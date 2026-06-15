# NS-STUDIO-AUDIT-001 — Narrative Studio Product / Beta Readiness Audit

## 1. Résumé exécutif

Statut du lot : **DONE documentaire**.

Verdict produit :

```text
Narrative Studio status : NOT_READY_FOR_BETA
Golden Slice Selbrume : NOT_READY_FOR_GOLDEN_SLICE
Fondations modèle/runtime : READY_WITH_GAPS
Expérience créateur no-code complète : PARTIAL
```

Le Narrative Studio possède déjà beaucoup plus qu'une façade : modèles core, workspaces editor, Scene graph, Storylines, Facts/World Rules, cinématiques V1, diagnostics par domaine, runtime Scene/Scenario, hooks Dialogue/Battle/Cinematic, save/load narratif et tests associés.

Mais il n'est pas encore bêta-ready comme produit no-code transversal. Les bloqueurs les plus structurants sont :

- le **Validateur global** est visible dans la sidebar comme `Non branché`, alors que les validateurs core existent par domaine ;
- le **Scene Builder** existe, mais la sidebar annonce encore `Scènes — Builder à venir`, et certains nodes restent en lecture seule ou en authoring partiel ;
- l'**Event Builder** / Map Event -> Scene est présent comme contrat authoring, mais l'UI dit encore `Lien authoring uniquement, runtime Scene à venir.` ;
- le flux bêta `Event -> Scene -> Dialogue -> Outcome -> Fact/Step` n'est pas prouvé comme expérience créateur complète ;
- les **World Rules** sont modélisées, authorables et testées, mais la donnée Selbrume actuelle contient `0` règle ;
- la Golden Slice Selbrume reste bloquée par V1-138 : Lysa/Lyra/rival, Port des Brisants et IDs canoniques demandent une confirmation humaine avant authoring.

Décision recommandée :

```text
Option C — faire d'abord un Event Builder / Event Inspector gap lot.
```

Pourquoi : le Narrative Studio ne peut pas devenir bêta-ready si le créateur ne peut pas brancher de manière no-code un événement de map vers une scène, puis vers dialogue/outcome/consequence, sans penser en IDs techniques. Le Validator doit venir très vite après, mais l'Event Builder est le verrou de création le plus central.

## 2. Verdict global

| Axe | Verdict | Justification courte |
|---|---|---|
| Modèles narratifs | READY_WITH_GAPS | `StorylineAsset`, `SceneAsset`, `CinematicAsset`, `NarrativeFact`, `WorldRuleDefinition`, `MapEventDefinition` existent. |
| UI Narrative Studio | PARTIAL | Shell et surfaces existent, mais `Scènes — Builder à venir` et `Validateur — Non branché` restent visibles. |
| Authoring no-code | PARTIAL | Storylines, cinématiques et Facts/World Rules sont avancés ; Events/Scenes/Validator restent incomplets comme flux utilisateur global. |
| Runtime narratif | PARTIAL_READY | Runtime Scene/Scenario, hooks et save/load existent, mais le wiring produit complet depuis l'authoring actuel n'est pas clos. |
| Selbrume | NOT_READY_FOR_GOLDEN_SLICE | V1-138 recommande V1-138-bis avant V1-139 à cause des IDs et du port. |
| Bêta PokeMap | NOT_READY_FOR_BETA | Les blockers narratifs Event/Scene/Validator empêchent une bêta no-code crédible. |

Verdict final :

```text
NS-STUDIO-AUDIT-001 : DONE
Narrative Studio : NOT_READY_FOR_BETA
Narrative Studio : NOT_READY_FOR_GOLDEN_SLICE
Prochain lot recommandé : NS-STUDIO-002 — Narrative Studio Event Builder / Event Scene Runtime Bridge Gap Closure
```

## 3. Rappel de l'objectif produit

L'objectif produit décrit dans `MVP Selbrume/narrative_studio.md` est clair : le Narrative Studio ne doit pas devenir un éditeur de flags. Il doit aider le créateur à penser en situations, événements, scènes, décisions, conséquences, progression et changements visibles du monde.

Le modèle canonique attendu est :

```text
Storyline
Chapter
Story Step
Event
Scene
Cinematic
Dialogue Yarn
Fact
World Rule
Validator
```

Les séparations de rôle sont importantes :

- `Event` déclenche ;
- `Scene` orchestre ;
- `Cinematic` met en scène une séquence linéaire ;
- `Yarn` porte le dialogue et les outcomes ;
- `Fact` représente une vérité lisible du monde ;
- `World Rule` projette passivement l'état narratif dans le monde ;
- `Validator` diagnostique le projet.

## 4. Méthode d'audit

Passes effectuées :

| Passe | Rôle | Verdict |
|---|---|---|
| Gate 0 | Capturer branche, état Git, diff initial. | OK, worktree propre au départ. |
| Règles | Lire `AGENTS.md`, `agent_rules.md`, `codex_rule.md` et skills demandés. | OK. |
| Vision produit | Lire docs MVP Selbrume et roadmaps phase. | OK. |
| Rapports récents | Lire V1-136, V1-137, V1-138 et roadmaps scènes. | OK. |
| Code statique | Auditer modèles, UI editor, runtime et tests par recherche ciblée. | OK. |
| Readiness | Classer modèle/UI/runtime/no-code/persistence/tests. | OK. |
| Critique | Identifier blockers bêta et suite actionnable. | OK. |

Note : `codex_rules.md` au pluriel est absent ; le repo contient `codex_rule.md`, qui a été lu.

Ce lot est audit-only. Aucun test Dart/Flutter n'a été relancé, car aucun code produit n'a été modifié. Les tests existants ont été inventoriés par fichiers et domaines.

## 5. État de l'UI observée

La capture fournie est cohérente avec le code :

```text
Narrative Studio
- Aperçu
- Storylines
- Scènes — Builder à venir
- Étapes
- Cinématiques
- Dialogues
- Facts
- Règles du monde — Actif
- Validateur — Non branché
```

L'écran `Règles du monde` montrant `1 Fact`, `0 Règle`, `0 Diagnostics` signifie surtout que la surface existe, mais que la donnée Selbrume ne contient pas encore de règle canonique. Le code confirme :

- `FactsWorldRulesWorkspace` permet de créer/éditer/supprimer facts et world rules ;
- `WorldRuleAuthoringOperations` et `WorldRuleDiagnostics` existent côté core ;
- `selbrume/project.json` contient bien `worldRules: 0`.

Le signal UX important n'est donc pas "World Rules absent", mais plutôt : la surface existe, la donnée finale n'existe pas, et le Validator global n'est pas branché pour dire si cela bloque le projet.

## 6. Matrice des concepts Narrative Studio

| Concept | Modèle | UI | Authoring no-code | Runtime | Persistance | Diagnostics | Tests | Statut bêta | Gaps |
|---|---|---|---|---|---|---|---|---|---|
| Storyline | READY | READY | PARTIAL | PARTIAL | READY | PARTIAL | READY | PARTIAL | Liaison runtime/progression encore fragmentée côté UX globale. |
| Chapter | READY | READY | PARTIAL | PARTIAL | READY | PARTIAL | READY | PARTIAL | Gestion visible surtout via Storyline/Steps. |
| Story Step | READY | READY | PARTIAL | PARTIAL | READY | PARTIAL | READY | PARTIAL | Besoin d'un chemin creator clair depuis Scene/Fact/Consequence. |
| Event | READY | PARTIAL | PARTIAL | PARTIAL | READY | READY | READY | NOT_READY | Event -> Scene existe en contrat, mais pas encore expérience no-code/runtime fermée. |
| Scene | READY | PARTIAL | PARTIAL | READY_WITH_GAPS | READY | READY | READY | PARTIAL | Graph fort, mais builder encore annoncé comme à venir et payloads partiellement authorables. |
| Cinematic | READY | READY | READY | PARTIAL | READY | READY | READY | READY_WITH_RESERVES | V1 editor-only fermé ; runtime cinematic complet reste hors V1. |
| Dialogue Yarn | PARTIAL | PARTIAL | PARTIAL | PARTIAL_READY | READY | PARTIAL | PARTIAL | PARTIAL | Studio/dialogue contracts existent ; authoring no-code de branches/outcomes pas encore entièrement produit. |
| Fact | READY | READY | READY | READY | READY | READY | READY | READY_WITH_GAPS | Donnée Selbrume canonique absente sauf `fact_test`. |
| World Rule | READY | READY | READY | READY | READY | READY | READY | READY_WITH_GAPS | Système prêt, mais aucune rule Selbrume et Validator global non branché. |
| Validator | PARTIAL | MISSING | MISSING | PARTIAL | N/A | READY_BY_DOMAIN | READY | NOT_READY | Core validators existent ; entrée Narrative Studio globale non branchée. |

## 7. Analyse Storylines / Steps

Les storylines sont bien un domaine réel du repo :

- modèles : `StorylineAsset`, chapters, steps ;
- tests : `storyline_asset_test.dart`, `storyline_authoring_operations_test.dart`, `storylines_workspace_*`;
- UI : `StorylinesWorkspace`, `GlobalStoryStudio*`.

Le statut est **PARTIAL** pour la bêta, parce que le lien utilisateur final reste encore dispersé : un créateur peut voir et manipuler des structures, mais le chemin "une scène consomme un événement, produit un outcome, complète un step et modifie le monde" n'est pas encore une ligne droite no-code et validée.

Pour Selbrume, V1-138 a trouvé des storylines, dont `story_main_brume_phare`, mais sans contenu canonique suffisant pour authorer directement la slice.

## 8. Analyse Events

Le modèle Event est présent :

- `MapEventDefinition` porte des pages conditionnelles ;
- `MapEventSceneTarget` relie une page d'event à une `SceneAsset` ;
- `event_scene_link_diagnostics.dart` diagnostique les liens scene ;
- `event_properties_panel.dart` expose un sélecteur `Scene V1`.

Mais l'audit relève un frein produit majeur : le panneau Event affiche encore le statut suivant :

```text
Lien authoring uniquement, runtime Scene à venir.
```

Le modèle dit aussi que le contrat `MapEventSceneTarget` "ne lance rien en runtime" et décrit seulement que la page active pointe vers une scène existante.

Conclusion : **Event est le principal P0 produit côté Narrative Studio**. Les briques existent, mais le créateur bêta a besoin d'un Event Builder/Inspector qui permette de configurer :

- pourquoi un event démarre ;
- quand il démarre ;
- quelle scène il lance ;
- quelles conditions il lit ;
- quelles conséquences il applique ou délègue ;
- comment le Validator prouve que le chemin est jouable.

Sans cela, la boucle `Event -> Scene -> Dialogue -> Outcome -> Fact/Step` reste trop technique.

## 9. Analyse Scene Builder

Les scènes sont avancées côté modèle et rendu graph :

- `SceneAsset` existe ;
- `SceneRuntimePlan` et `SceneRuntimeExecutor` existent ;
- le graph a nodes, ports, edges, layouts ;
- `SceneGraphReadOnlyView` sait afficher et déplacer localement les nodes ;
- `SceneNodeReadOnlyInspector` couvre des payloads `yarnDialogue`, `battle`, `cinematic`, `condition`, `action`, `branchByOutcome`, `merge`.

Mais le nom et les libellés actuels signalent une limite : `ReadOnlyView`, `ReadOnlyInspector`, sidebar `Scènes — Builder à venir`. Certains payloads sont authorables, mais d'autres restent en lecture seule ou en authoring V0.

Réponse à la question obligatoire :

```text
Le Scene Builder n'est pas encore réellement utilisable par un créateur no-code pour authorer toute la Golden Slice Selbrume de bout en bout.
```

Il est proche d'un outil de visualisation/édition partielle robuste, mais pas encore un builder complet comparable à l'ambition produit.

## 10. Analyse Cinematic Builder

Le Cinematic Builder est la surface la plus close du Narrative Studio.

V1-136 a conclu :

```text
Cinematic Builder V1 : CLOSABLE AVEC RÉSERVES NON BLOQUANTES
```

Puis V1-136-bis a nettoyé les attentes de tests legacy. Les lots V1-130 à V1-135 ont fermé la séquence caméra editor-only.

Statut :

- authoring : READY ;
- preview editor-only : READY ;
- diagnostics : READY_WITH_RESERVES ;
- runtime cinematic complet : OUT_OF_SCOPE_V1 / PARTIAL ;
- capacité Golden Slice : suffisante pour des séquences editor-only et authoring, pas pour promettre une vraie caméra runtime.

Conclusion : il ne faut pas rouvrir le Cinematic Builder pour résoudre la readiness Narrative Studio. Les vrais verrous sont Event, Scene, Validator et Selbrume data.

## 11. Analyse Dialogue Yarn

Le repo contient une surface Dialogue Studio et des contrats dialogue :

- `dialogue_studio_workspace.dart` ;
- widgets/tests de dialogue ;
- adapters runtime Scene Dialogue awaitable ;
- tests `dialogue_*`, `scene_dialogue_runtime_awaitable_adapter_test.dart`, `outcome_scene_branch_readiness_test.dart`.

Le statut est **PARTIAL** :

- Yarn peut être encodé et prévisualisé ;
- le runtime peut attendre des dialogues dans une scène ;
- les outcomes existent dans les tests ;
- mais la création no-code complète de branches, outcomes, consequences et liens Story Step n'est pas encore prouvée comme parcours produit.

Pour Selbrume, les dialogues actuels ne sont pas canoniques : `g.yarn` est placeholder et `test.yarn` est prototype.

## 12. Analyse Facts / World Rules

Facts et World Rules sont bien modélisés et outillés :

- `NarrativeFact` ;
- `WorldRuleDefinition` ;
- `WorldRuleAuthoringOperations` ;
- `WorldRuleDiagnostics` ;
- `FactsWorldRulesWorkspace` ;
- tests core et widget.

L'écran actuel `1 Fact`, `0 Règle`, `0 Diagnostics` est cohérent avec `selbrume/project.json` :

```json
{
  "facts": 1,
  "worldRules": 0
}
```

Ce n'est pas un manque de système, c'est un manque de contenu canonique et de validation globale. Pour la bêta, le point dur est que les world rules doivent devenir visibles en runtime et être validées comme partie du chemin jouable.

## 13. Analyse Validator

Le statut du Validator est le plus important à clarifier.

Il existe des validateurs core :

- `narrative_validator.dart` ;
- `narrative_validator_authoring_adapter.dart` ;
- `beta_playability_validator.dart` ;
- diagnostics Scene/Event/WorldRule.

Il existe aussi un validator editor général pour d'autres domaines (`pokemon_project_validator.dart`), mais la sidebar Narrative Studio dit encore :

```text
Validateur — Non branché
```

Décision :

```text
Validator status = PARTIAL
Validator UI status = MISSING
Validator beta status = NOT_READY
```

Le produit a les briques pour diagnostiquer, mais pas encore le bouton central "ce projet narratif est jouable / pas jouable" pour un créateur.

## 14. Analyse runtime / persistence narrative

Le runtime narratif possède de vraies briques :

- `SceneRuntimePlan` ;
- `SceneRuntimePlanBuilder` ;
- `SceneRuntimeExecutor` ;
- `SceneEventRuntimeHook` ;
- adapters Dialogue, Cinematic, Battle ;
- `SceneConsequenceRuntimeWriter` ;
- runtime story branching ;
- world rule projection hook ;
- save/load tests narratifs.

Les tests runtime inventoriés couvrent notamment :

- event source bridge ;
- fact/world rule projection ;
- outcome battle continuation ;
- save/load narrative state roundtrip ;
- scenario runtime golden path ;
- scene runtime golden slice smoke.

Mais l'audit produit reste conservateur : ce runtime n'est pas encore exposé comme boucle no-code complète dans le Narrative Studio. La persistance narrative existe par tests et services, mais le créateur n'a pas encore un Validator/UI global qui prouve le chemin depuis ses actions authoring.

## 15. Analyse Golden Slice Selbrume

V1-137 et V1-138 sont déterminants :

- V1-137 : `Golden slice narrative Selbrume : NOT_READY_FOR_DIRECT_AUTHORING` ;
- V1-138 : `V1-139_SHOULD_WAIT`.

Inventaire Selbrume actuel :

```json
{
  "maps": 10,
  "characters": 5,
  "dialogues": 2,
  "scenes": 1,
  "cinematics": 1,
  "storylines": 4,
  "facts": 1,
  "worldRules": 0,
  "trainers": 1,
  "encounterTables": 1
}
```

Blocages Selbrume :

- Lysa n'est pas tranchée entre `lyra`, `rival` ou un futur `lysa` ;
- `map_port_brisants` n'existe pas comme map dédiée ;
- `scene_test`, `cinematic_uwu`, `g.yarn`, `fact_test`, `grant` sont prototypes ;
- aucun dialogue Maël/Lysa canonique ;
- aucun battle `trainer_lysa_port` ;
- aucun fact/world rule canonique pour la progression.

Conclusion : Selbrume ne doit pas être authoré directement tant que les décisions V1-138-bis ne sont pas prises.

## 16. Matrice bêta Narrative Studio

| Capacité bêta | État actuel | Preuves | Bloquant ? | Gravité | Lot recommandé | Décision |
|---|---|---|---|---|---|---|
| Map Event -> Scene | PARTIAL | `MapEventSceneTarget`, diagnostics, UI selector ; wording runtime à venir. | Oui | P0_BLOCKER | NS-STUDIO-002 | Corriger avant bêta. |
| Scene -> Dialogue | PARTIAL_READY | Scene payload Yarn + runtime adapter + tests. | Oui | P1_REQUIRED | NS-STUDIO-003 | Finaliser authoring no-code. |
| Dialogue -> Outcome | PARTIAL_READY | outcome tests et branch readiness. | Oui | P1_REQUIRED | NS-STUDIO-003 | Relier à consequences/facts. |
| Scene -> Battle | PARTIAL_READY | battle payload + runtime outcome adapter. | Oui | P1_REQUIRED | NS-STUDIO-003 | Valider workflow no-code. |
| Battle outcome -> Fact | PARTIAL | consequence writer existe, mais UX globale incomplète. | Oui | P1_REQUIRED | NS-STUDIO-003 | Exposer et valider. |
| Scene consequence -> Story Step | PARTIAL | consequence model/runtime tests. | Oui | P1_REQUIRED | NS-STUDIO-003 | Stabiliser workflow creator. |
| World Rule runtime projection | PARTIAL_READY | core/runtime hook/tests. | Oui | P1_REQUIRED | NS-STUDIO-004 | Brancher validator UI et données Selbrume. |
| Conditional dialogue | PARTIAL | docs/tests, pas encore workflow complet Selbrume. | Oui | P1_REQUIRED | NS-STUDIO-004 | Prouver dans slice. |
| Consumed events persistence | PARTIAL_READY | save/load narrative tests. | Oui | P1_REQUIRED | NS-STUDIO-004 | Prouver via authoring actuel. |
| Storyline progression | PARTIAL | Storyline models/UI/tests. | Oui | P1_REQUIRED | NS-STUDIO-004 | Connecter Scene outcomes. |
| Save/load narrative state | PARTIAL_READY | runtime save/load tests. | Oui | P1_REQUIRED | NS-STUDIO-004 | Prouver golden slice réelle. |
| Validator playable project | NOT_READY | Validator UI non branché. | Oui | P0_BLOCKER | NS-STUDIO-005 | Brancher globalement. |
| Golden Slice Selbrume | NOT_READY | V1-138 : V1-139_SHOULD_WAIT. | Oui | P0_BLOCKER | V1-138-bis | Confirmer IDs avant contenu. |

## 17. Matrice UX no-code

| Surface | Ce que l'utilisateur voit | IDs techniques visibles ? | Pickers ? | Diagnostics humains ? | Statut UX | Risque |
|---|---|---|---|---|---|---|
| Narrative Studio overview | Shell Narrative Studio. | Peu | Oui partiel | Partiel | PARTIAL | Navigation promet des surfaces non branchées. |
| Storylines | Storylines/chapters/steps. | Partiel | Oui | Partiel | PARTIAL_READY | Lien runtime encore peu lisible. |
| Étapes | Étapes narratives. | Partiel | Oui | Partiel | PARTIAL | Complétion par Scene/Fact à clarifier. |
| Scènes | `Builder à venir`. | Oui possible dans détails | Partiel | Oui par domaine | PARTIAL | Promesse UI pas encore tenue. |
| Cinématiques | Library + Builder V1. | Non comme workflow principal | Oui | Oui | READY | Runtime cinematic complet hors V1. |
| Dialogues | Studio/Explorer. | Partiel | Partiel | Partiel | PARTIAL | Outcomes/consequences pas encore assez guidés. |
| Facts | Workspace facts. | Non principal | Oui | Oui | READY_WITH_GAPS | Données Selbrume manquantes. |
| Règles du monde | Formulaire règle, source/cible/effet. | Non principal | Oui | Oui | READY_WITH_GAPS | 0 règle dans Selbrume. |
| Validateur | `Non branché`. | N/A | N/A | Core seulement | MISSING_UI | Gros blocker bêta. |
| Map Event inspector | Scene target dropdown + conditions. | Oui via raw JSON possible | Oui | Oui | PARTIAL | Runtime Scene annoncé à venir. |
| Scene Builder | Graph/read-only/authoring partiel. | Partiel | Partiel | Oui | PARTIAL | Pas assez créateur pour slice complète. |
| Cinematic Builder | No-code avancé. | Non principal | Oui | Oui | READY | Ne pas rouvrir pour les blockers NS. |

## 18. Gaps bloquants

| Gap | Domaine | Impact | Gravité | Décision |
|---|---|---|---|---|
| Validator global non branché | Validator | Le créateur ne peut pas savoir si son histoire est jouable. | P0_BLOCKER | NS-STUDIO-005 |
| Event Builder incomplet | Events | Impossible de fermer la boucle Map Event -> Scene en no-code. | P0_BLOCKER | NS-STUDIO-002 |
| Scene Builder authoring partiel | Scenes | Impossible d'authorer toute la golden slice sans expertise. | P1_REQUIRED | NS-STUDIO-003 |
| Event -> Scene runtime produit non clos | Runtime bridge | Le wording actuel dit runtime à venir. | P1_REQUIRED | NS-STUDIO-002 |
| Selbrume IDs non tranchés | Content | Risque de créer le mauvais contenu. | P0_BLOCKER | V1-138-bis |
| World rules Selbrume absentes | Content/runtime projection | Progression visible impossible dans la slice. | P1_REQUIRED | V1-139 après V1-138-bis |
| Dialogues canoniques absents | Dialogue | Slice narrative injouable. | P1_REQUIRED | V1-139/V1-140 |
| Battle Lysa absent | Battle/narrative | Outcome rival absent. | P1_REQUIRED | V1-140 |

## 19. Backlog V2

| Domaine | Item | Raison du report |
|---|---|---|
| Runtime cinematic | Vraie caméra runtime, pan/zoom, interpolation. | Hors Cinematic Builder V1. |
| Timeline avancée | Drag horizontal, reorder, overlap temporel avancé. | Pas nécessaire pour fermer la bêta narrative minimale. |
| Dialogue avancé | Éditeur Yarn complet avec branches complexes. | La bêta a besoin d'un chemin simple d'abord. |
| Audio/FX narratifs | Audio timeline, FX avancés. | Hors flux Event/Scene/Fact minimum. |
| Storyboard | Shot strip, production tools. | V2 productivité, pas bêta blocker. |
| Validator avancé | Couverture assets/audio/perf complète. | Le V1 doit d'abord brancher le validator jouabilité. |

## 20. Proposition de prochains lots

| Ordre | Lot proposé | Type | Objectif | Pourquoi maintenant | Non-objectifs | Dépendances | Critère de sortie |
|---|---|---|---|---|---|---|---|
| 1 | NS-STUDIO-002 — Narrative Studio Event Builder / Event Scene Runtime Bridge Gap Closure | Product gap | Fermer Event -> Scene comme flux créateur no-code. | C'est le verrou central. | Pas de refonte Scene, pas Selbrume content. | Modèles Event/Scene existants. | Event peut lancer une Scene via UI no-code et statut runtime honnête. |
| 2 | NS-STUDIO-003 — Scene Builder No-Code Authoring Closure V0 | Product gap | Rendre les nodes minimum authorables pour golden slice. | Scene orchestre Dialogue/Battle/Cinematic/Consequence. | Pas de nouveau moteur. | NS-STUDIO-002. | Créateur peut construire une scène simple sans JSON. |
| 3 | NS-STUDIO-004 — Narrative Runtime End-to-End Smoke from Authored Project | Validation | Prouver Event -> Scene -> Dialogue -> Outcome -> Fact/Step -> Save/load. | Les briques runtime existent mais doivent être consommées ensemble. | Pas de feature UI lourde. | NS-STUDIO-002/003. | Smoke test vert sur fixture authorée. |
| 4 | NS-STUDIO-005 — Narrative Validator UI Integration V0 | UI/validation | Brancher le Validateur sidebar. | Il est visible comme non branché. | Pas de validator parfait V2. | Diagnostics core existants. | UI affiche readiness jouable no-code. |
| 5 | NS-SCENES-V1-138-bis — Selbrume Golden Slice Canonical ID Decision Closure | Product decision | Fermer Lysa/Lyra/rival/port. | Nécessaire avant contenu Selbrume. | Pas d'authoring contenu. | V1-138. | Karim confirme les IDs. |
| 6 | NS-SCENES-V1-139 — Selbrume Golden Slice Canonical Content Scaffolding V0 | Content | Créer drafts contrôlés. | Après décisions et minimum NS. | Pas dialogue final complet. | V1-138-bis + NS gaps. | Scaffolding canonique sans prototypes. |

## 21. Décision recommandée

Décision principale :

```text
Option C — faire d'abord un Event Builder / Event Inspector gap lot.
```

Raison : sans Event Builder clair, le reste du Narrative Studio reste une collection de briques fortes mais difficilement utilisables par un créateur. Le flux bêta commence au déclenchement : parler à un PNJ, entrer dans une zone, examiner un objet, lancer une scène, produire une conséquence.

Décision secondaire :

```text
V1-138-bis reste nécessaire avant tout authoring Selbrume réel.
```

Le Validator est également P0 pour la bêta, mais il doit diagnostiquer un flux que le créateur peut produire. D'où l'ordre recommandé : Event gap, Scene authoring, smoke runtime, Validator UI, puis Selbrume content.

## 22. Non-objectifs confirmés

Ce lot n'a pas :

- modifié `packages/**` ;
- modifié `examples/**` ;
- modifié `assets/**` ;
- modifié `selbrume/**` ;
- modifié `pubspec.yaml` ;
- créé de screenshot ;
- créé de Visual Gate ;
- lancé V1-139 ;
- rouvert le Cinematic Builder ;
- ajouté de feature produit.

## 23. Auto-critique finale

Le rapport est volontairement sévère. Le repo contient beaucoup de preuves positives, notamment côté runtime et tests. Le risque serait de sous-estimer ces fondations parce que l'UI montre encore des libellés `à venir`.

Mais le jugement bêta doit rester orienté utilisateur : un créateur non développeur doit pouvoir aller de l'idée narrative à un événement jouable, persistant et validé. Aujourd'hui, ce chemin existe en morceaux, mais pas encore comme expérience complète.

Le plus grand risque de suite serait de continuer Selbrume en écrivant du contenu sur des IDs ambigus, ou de brancher le Validator avant d'avoir clarifié le flux Event/Scene que le Validator doit expliquer.

## 24. Critique du prompt

Le prompt est très large pour un seul audit. Il couvre presque tout le Narrative Studio, le runtime narratif, Selbrume et la bêta globale. C'est utile comme checkpoint, mais cela limite la profondeur possible sur chaque surface sans lancer l'app manuellement.

Un audit uniquement fichier/code ne suffit pas à juger finement :

- la fluidité réelle des pickers ;
- les états de scroll ;
- les messages visibles exacts dans tous les cas ;
- la compréhension utilisateur sans contexte développeur ;
- le comportement d'une vraie session authoring complète.

Une session UI manuelle serait nécessaire avant de déclarer le Narrative Studio prêt pour bêta. Le prochain lot recommandé ne devrait donc pas être un gros chantier de contenu, mais un lot ciblé Event Builder / Event Scene Bridge, suivi d'un smoke runtime et d'un Validator UI.
