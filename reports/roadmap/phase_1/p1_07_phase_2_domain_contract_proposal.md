# P1-07 — Phase 2 Domain Contract Proposal

## 1. Résumé exécutif

P1-07 transforme les décisions produit de Phase 1 en proposition de contrats domaine pour Phase 2, sans commencer Phase 2.

Recommandation centrale :

```text
Phase 2 doit construire le plus petit socle domaine utile :
diagnostics, descriptors, adapters et read models avant modèles persistants.
```

Contrats recommandés en Phase 2 :

```text
- Story Step Descriptor / Storyline metadata légère ;
- Event Authoring Source Contract ;
- Scene / ScenarioAsset Adapter Contract ;
- Yarn Outcome Reference Contract ;
- Battle Reference / Outcome Contract minimal ;
- Fact Descriptor ou Fact Presentation Layer ;
- World Rule Authoring / Predicate Adapter Contract ;
- Validator Diagnostic Expansion ;
- Reference Registry / Picker Sources read-only.
```

Contrats à reporter ou à refuser maintenant :

```text
- Quest Engine complet ;
- Quest Journal ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- Reward Model unifié si money/XP ne sont pas cadrés ;
- Door/Warp Engine complet ;
- Static wild encounter authoring complet ;
- UI moderne/premium ;
- projet disque Selbrume complet.
```

La stratégie proposée évite de tout coder trop tôt :

```text
1. Auditer l’existant avant de créer.
2. Ne créer un contrat que s’il a des consumers explicites.
3. Préférer un adapter/read model lorsque le stockage existe déjà.
4. Séparer contrat domaine et contrat JSON.
5. Reporter ProjectManifest/migrations tant que le besoin persistant n’est pas prouvé.
```

Roadmap Phase 2 proposée : une suite bornée de lots de domaine, de l’inventaire existant vers les diagnostics et picker sources, avec checkpoint de clôture.

Prochain lot exact après P1-07 :

```text
P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
```

## 2. Scope du lot

Inclus :

```text
- lecture des roadmaps, rapports Phase 1 et rapports NS-GS demandés ;
- inspection read-only des structures existantes pertinentes ;
- proposition de contrats Phase 2 ;
- distinction créer / adapter / reporter ;
- proposition de lots Phase 2 sans exécution ;
- mise à jour de MVP Selbrume/road_map_phase_1.md ;
- Evidence Pack complet.
```

Exclus :

```text
- aucun code modifié ;
- aucun test lancé ;
- aucun package modifié ;
- aucun modèle map_core créé ;
- aucun schéma JSON créé ;
- aucun fichier Freezed / JsonSerializable créé ;
- aucun build_runner lancé ;
- aucune roadmap Phase 2 vivante créée ;
- aucune UI créée ;
- aucun contenu final Selbrume créé ;
- aucun project.json Selbrume créé ;
- P1-CHECKPOINT-01 non démarré.
```

Fichiers créés :

```text
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
```

Fichiers modifiés :

```text
MVP Selbrume/road_map_phase_1.md
```

Fichiers explicitement non modifiés :

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
packages/map_core
packages/map_gameplay
packages/map_battle
packages/map_runtime
packages/map_editor
examples/playable_runtime_host
```

## 3. Sources lues

Roadmaps et cadrage :

| Source | Rôle dans P1-07 |
|---|---|
| `MVP Selbrume/road_map_global.md` | Contexte global lu, non modifié. |
| `MVP Selbrume/road_map_phase_1.md` | Roadmap vivante Phase 1 à mettre à jour. |
| `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` | Vision produit phasée complète. |
| `reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md` | Bootstrap de gouvernance globale. |
| `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md` | Cadre de Phase 1. |
| `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` | Modèle canonique produit. |
| `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` | Frontières Event / Scene / Cinematic. |
| `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` | Grammaire Fact / World Rule. |
| `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` | Structure Storyline / Chapter / Story Step. |
| `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` | Mapping conceptuel Selbrume. |
| `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` | Workflows no-code et picker sources attendues. |
| `MVP Selbrume/road_map.md` | Roadmap historique NS-GS et contexte ancien. |
| `MVP Selbrume/narrative_studio.md` | Vision historique Narrative Studio. |
| `MVP Selbrume/selbrume.md` | Référence conceptuelle Selbrume. |

Rapports NS-GS :

| Source | Rôle dans P1-07 |
|---|---|
| `reports/gameplay/audit/narrative_studio_product_model_v0.md` | Modèle produit Narrative Studio historique. |
| `reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md` | Contrat event/scene/outcome/fact pré-Phase 1. |
| `reports/gameplay/audit/sel_b2_battle_from_scene.md` | Battle depuis Scene et handoff. |
| `reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md` | Preuve Level 2 interaction PNJ vers scène. |
| `reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md` | Preuve outcome technique vers branching scène. |
| `reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md` | Preuve présence/dialogue conditionnels. |
| `reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md` | Preuve trainer battle depuis scène. |
| `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` | Clarification Level 2 Application, non Flame/disk. |
| `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` | Validator narratif V0 existant. |
| `reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md` | GiveItem / pickup et limites item. |
| `reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md` | Gate via fact dérivé, pas hasItem direct. |
| `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` | Side quest comme pattern facts/steps/scenes. |
| `reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md` | Boss trainer-like prouvé, static wild authoring non prouvé. |
| `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` | Rewards item partiels, money/XP non cadrés. |
| `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` | Synthèse NS-GS et limites Level 2 / Flame / disk. |

Structures inspectées en lecture seule :

| Source | Observation utile |
|---|---|
| `packages/map_core/lib/src/models/scenario_asset.dart` | `ScenarioAsset`, `ScenarioScope`, nodes, edges, `declaredOutcomes`, activation condition. |
| `packages/map_core/lib/src/models/project_manifest.dart` | `ProjectManifest` porte déjà scenarios, dialogues, trainers, maps. |
| `packages/map_core/lib/src/models/script_conditions.dart` | Conditions flags/variables/party/map, pas `stepCompleted`, pas `hasItem`. |
| `packages/map_core/lib/src/models/game_state.dart` | `GameState` porte storyFlags, scriptVariables, progression, bag. |
| `packages/map_core/lib/src/models/save_data.dart` | `completedStepIds`, money, bag, party persistent. |
| `packages/map_core/lib/src/models/map_entity_payloads.dart` | `MapEntityRuntimePredicate`, visibility/dialogue conditionnels. |
| `packages/map_core/lib/src/operations/narrative_validator.dart` | Diagnostics V0 multi-diagnostics. |
| `packages/map_core/lib/src/validation/validators.dart` | `ProjectValidator` existant, validation stricte première erreur. |
| `packages/map_gameplay/lib/src/game_state_mutations.dart` | Mutations pures `setFlag`, `giveItem`, `completeStep`. |
| `packages/map_gameplay/lib/src/script_condition_evaluator.dart` | Évaluation pure des `ScriptCondition`. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart` | Source events runtime et effects. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart` | Sources/actions scénario existantes. |
| `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart` | Convention `battle:<battleId>:<outcome>`. |
| `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart` | Projection passive GameState vers présence/dialogue. |
| `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart` | Chapitres lus depuis metadata Step/Global Story Studio. |
| `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart` | World changes Step Studio via metadata, principalement PNJ. |
| `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart` | Projection UI read-only, pas domaine canonique. |
| `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart` | Step Studio authoring dans metadata JSON editor. |
| `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart` | Global Story / Chapter authoring dans metadata JSON editor. |
| `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` | Use cases CRUD ScenarioAsset existants. |

Aucun fichier obligatoire n’a été signalé absent au moment de la lecture.

## 4. Synthèse des décisions Phase 1

Décisions consolidées :

```text
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Storyline organise une ligne narrative.
Chapter organise une section.
Story Step décrit un jalon.
Side quest V0 = Storyline secondaire.
Validator diagnostique.
No-code workflow = pickers + validations + diagnostics.
```

Conséquence pour Phase 2 :

```text
Les contrats domaine doivent stabiliser les références, les labels humains,
les diagnostics et les sources de picker sans recréer tous les systèmes.
```

## 5. Objectif de la Phase 2

Objectif recommandé :

```text
Transformer les décisions produit Phase 1 en contrats domaine minimaux,
testables, validables et utilisables par les phases suivantes.
```

Phase 2 devrait rester :

```text
- map_core / domaine pur d’abord ;
- diagnostics d’abord ;
- adapters/read models avant persistence ;
- aucune intégration Flame lourde ;
- aucune UI premium ;
- aucun contenu final Selbrume ;
- aucun projet disque Golden Slice complet.
```

La Phase 2 ne doit pas devenir une implémentation massive du Narrative Studio. Elle doit préparer proprement Phase 3 runtime/disk, Phase 4 authoring minimal, Phase 6 Selbrume Golden Slice et Phase 7 UI finale.

## 6. Stratégie de traduction produit → domaine

Stratégie proposée :

```text
1. Ne pas créer tous les modèles d’un coup.
2. Commencer par l’audit des modèles existants.
3. Identifier ce qui existe déjà : ScenarioAsset, completedStepIds,
   storyFlags, predicates, metadata Step Studio, validator.
4. Créer seulement les contrats manquants avec consumers clairs.
5. Préférer adapters / presentation contracts si le stockage existe déjà.
6. Ajouter diagnostics avant UI.
7. Reporter JSON/migrations si le modèle n’est pas encore stable.
```

Règle importante :

```text
Contrat ≠ forcément nouveau modèle persistant.
```

Un contrat peut être :

```text
- une convention validée ;
- une vue read-only ;
- un descriptor ;
- un adapter ;
- un diagnostic ;
- une source de picker pure.
```

## 7. Principes de sélection des contrats

Chaque contrat proposé doit documenter :

```text
- consumer explicite ;
- source de vérité ;
- persistence nécessaire ou non ;
- runtime consumer ou non ;
- editor consumer ou non ;
- diagnostics Validator possibles ;
- migration risk ;
- testability ;
- backwards compatibility.
```

Matrice de décision :

| Décision | Quand l’utiliser | Exemple Phase 2 |
|---|---|---|
| Créer maintenant | Consumer clair, source de vérité absente, diagnostics bloqués sans contrat. | Story Step Descriptor si les pickers/validator en dépendent. |
| Adapter existant | Stockage existant suffisant, besoin de labels/diagnostics. | Scene / ScenarioAsset Adapter, World Rule / Predicate Adapter. |
| Reporter | Besoin réel mais dépend de runtime/UI/gameplay futurs. | Reward Model unifié, static wild authoring. |
| Refuser maintenant | Risque de sur-modélisation ou système prématuré. | Quest Engine obligatoire en Phase 2. |

## 8. Inventaire des concepts candidats

| Concept candidat | Classement recommandé | Justification |
|---|---|---|
| Storyline | Phase 2 recommandé, léger | Besoin labels, sideQuest type, pickers, validator. |
| Chapter | Phase 2 optionnel/léger | Metadata utile, peut rester optionnel. |
| Story Step | Phase 2 recommandé | `completedStepIds` existe, mais il manque un descriptor produit validable. |
| Event | Phase 2 recommandé | Sources runtime existent, authoring/validator doivent les formaliser. |
| Scene | Phase 2 recommandé via adapter | `ScenarioAsset` existe déjà. |
| Cinematic | Phase 2 optionnel minimal | Référence/diagnostic seulement, pas builder. |
| Dialogue Yarn outcome | Phase 2 recommandé | Outcomes doivent être sélectionnables et diagnostiqués. |
| Battle reference | Phase 2 recommandé minimal | Scene lance battle, refs trainer/battle doivent être validables. |
| Battle outcome | Phase 2 recommandé minimal | `victory` / `defeat` d’abord ; autres à cadrer. |
| Fact | Phase 2 recommandé sous forme descriptor/presentation | Éviter flags bruts, ne pas dupliquer GameState. |
| World Rule | Phase 2 recommandé via predicate adapter | Predicates existent, besoin langage auteur et diagnostics. |
| Validator diagnostic | Phase 2 recommandé | Valeur centrale no-code. |
| Reference Registry | Phase 2 recommandé comme read model | Source des pickers, pas UI. |
| Picker Source | Phase 2 recommandé comme read model | Alimente Phase 4. |
| Reward | Reporter gameplay future / Phase 5 | NS-GS-18 montre money/XP non cadrés. |
| Quest Journal | Reporter UI future | Pas nécessaire pour sideQuest V0. |
| Door/Warp Gate | Reporter Phase 3/5 | Gate V0 via facts ; Door Engine absent. |
| Static Wild Encounter | Reporter gameplay future | Boss trainer-like prouvé, static wild scenario non prouvé. |
| Money/XP Reward | Reporter gameplay future | État partiel/absent. |

## 9. Contrat Storyline / Chapter / Story Step

Pourquoi nécessaire :

```text
Les steps ne doivent pas rester une liste de flags/IDs.
Les pickers, diagnostics et workflows no-code ont besoin de labels humains,
relations Storyline/Chapter et sources de complétion.
```

Ce qui existe déjà :

```text
- `GameState.progression.completedStepIds` ;
- `ScenarioAsset.scope == globalStory` ;
- metadata editor `authoring.stepStudioDocument` ;
- metadata editor `authoring.globalStoryStudioDocument` ;
- `GlobalStoryChapterStepIndex` runtime lit les chapters depuis metadata ;
- `NarrativeWorkspaceProjection` fournit une vue UI read-only.
```

Ce qui manque :

```text
- source domaine pure et stable des labels Storyline / Chapter / Step ;
- descriptor validable des steps ;
- distinction claire entre step storage technique et step produit ;
- diagnostics pour steps jamais activables, inconnus, orphelins ;
- statut de sideQuest comme Storyline secondaire sans Quest Engine.
```

Source de vérité recommandée :

```text
Phase 2 doit décider si la source de vérité reste `ScenarioAsset.metadata`
temporairement ou si un descriptor minimal doit vivre dans map_core.
```

Contrat minimal recommandé :

```text
StoryStepDescriptor:
- id ;
- label humain ;
- parent Storyline ;
- Chapter optionnel ;
- availability summary ;
- completion source attendue ;
- related facts ;
- related events/scenes ;
- notes auteur.
```

Storyline / Chapter peuvent démarrer comme metadata ou descriptors légers :

```text
StorylineDescriptor:
- id ;
- label ;
- type main / sideQuest / tutorial / optional ;
- entry step ;
- completion summary.

ChapterDescriptor:
- id ;
- label ;
- order ;
- step ids.
```

Diagnostics possibles :

```text
- Storyline sans step ;
- Chapter vide ;
- Step inconnu lu par Event / World Rule ;
- Step jamais complété ;
- Step complété mais jamais lu ;
- sideQuest disponible sans Event d’entrée.
```

Risques :

```text
- créer un Quest Engine prématuré ;
- dupliquer `completedStepIds` ;
- rendre Chapter obligatoire runtime ;
- migrer ProjectManifest trop tôt.
```

Lot Phase 2 proposé : oui, après inventaire existant.

## 10. Contrat Event

Rappel :

```text
Event déclenche.
```

Ce qui existe déjà :

```text
- `ScenarioRuntimeSourceEvent.mapEnter` ;
- `ScenarioRuntimeSourceEvent.triggerEnter` ;
- `ScenarioRuntimeSourceEvent.entityInteract` ;
- `ScenarioRuntimeSourceEvent.outcomeReceived` ;
- action kinds source : `sourceMapEnter`, `sourceTriggerEnter`,
  `sourceEntityInteract`, `sourceOutcome` ;
- bindings `mapId`, `triggerId`, `entityId`, `outcomeId`.
```

Ce qui manque :

```text
- langage auteur stable pour "Déclencheur" ;
- contrat de source authoring validable ;
- mapping source auteur → source runtime ;
- diagnostics Event sans source, source absente, target Scene absente ;
- repeat policy / one-shot comme décision explicite.
```

Recommandation :

```text
Formaliser un Event Authoring Contract minimal seulement pour alimenter
pickers et validator. Ne pas dupliquer les runtime source events.
```

Contrat minimal :

```text
EventAuthoringSource:
- trigger type ;
- source map/entity/trigger/outcome ;
- target scene/scenario ;
- conditions d’entrée ;
- repeat policy ;
- label humain.
```

Consumers explicites :

```text
map_editor future authoring, Validator, reference picker sources,
map_runtime adapter.
```

## 11. Contrat Scene et relation à ScenarioAsset

Sujet critique :

```text
Scene est-elle ScenarioAsset ?
Scene est-elle un wrapper produit au-dessus de ScenarioAsset ?
Scene est-elle une future projection editor seulement ?
```

Options :

| Option | Description | Avantages | Risques |
|---|---|---|---|
| A | Scene = nom produit de `ScenarioAsset` | Aucun modèle nouveau, compatible runtime. | Le nom "Scenario" reste technique et peut mélanger story/local/cutscene. |
| B | `SceneContract` wrapper persistant autour de `ScenarioAsset` | Clarté produit forte. | Migration ProjectManifest, duplication, refactor large. |
| C | Scene authoring/read-only adapter | Labels humains et diagnostics sans migration lourde. | Peut devenir une couche intermédiaire si mal tenue. |

Recommandation P1-07 :

```text
Commencer par C : Scene / ScenarioAsset Adapter Contract.
```

Justification :

```text
`ScenarioAsset` supporte déjà nodes, edges, scope, outcomes, activation
condition et execution runtime. Phase 2 doit d’abord clarifier la vue produit
et les diagnostics, pas casser ce contrat.
```

Impact migration :

```text
Faible si adapter read-only.
Élevé si wrapper persistant.
```

Impact validator/editor :

```text
Un adapter permet de diagnostiquer "Scene" avec vocabulaire produit,
tout en gardant `ScenarioAsset` comme source de vérité technique.
```

## 12. Contrat Cinematic reference

P1-02 et P1-06 ont fixé :

```text
Cinematic met en scène.
Scene référence une Cinematic.
Cinematic Builder complet reporté.
```

Ce qui existe :

```text
- `RuntimeCutsceneAsset` runtime minimal ;
- `CutsceneRuntimeRunner` ;
- Cutscene Studio editor existant ;
- Step Studio lie des cutscenes via metadata.
```

Recommandation Phase 2 :

```text
Créer ou formaliser seulement un contrat de référence minimal :
CinematicRef / CutsceneRef.
```

Contrat minimal :

```text
- cinematicId ;
- label humain si disponible ;
- rôle dans la Scene : entrée, réaction, sortie, completion ;
- source scenario/cutscene existante ;
- diagnostics référence absente.
```

Non-objectifs Phase 2 :

```text
- timeline model riche ;
- Cinematic Builder complet ;
- commands caméra/animation persistantes nouvelles ;
- logique narrative dans Cinematic.
```

## 13. Contrat Dialogue Yarn outcome

Rappel :

```text
Yarn produit outcomes.
Scene interprète outcomes.
```

Ce qui existe :

```text
- `declaredOutcomes` dans `ScenarioAsset` ;
- action `emitOutcome` ;
- source `sourceOutcome` / `outcomeReceived` ;
- convention `scenario.outcome.<outcomeId>` ;
- `NarrativeWorkspaceProjection` collecte émetteurs/consommateurs.
```

Question :

```text
Faut-il un OutcomeRegistry ?
```

Recommandation :

```text
Non au départ. Commencer par un Outcome Reference Contract / adapter de
présentation et diagnostics.
```

Contrat minimal :

```text
- outcomeId ;
- label humain optionnel ;
- producer Yarn/Scene ;
- consumers Scene/Step ;
- durable ou temporaire ;
- fact lié si durable.
```

Diagnostics :

```text
- outcome déclaré jamais émis ;
- outcome émis jamais consommé ;
- outcome consommé jamais émis ;
- outcome durable sans Fact ;
- outcome affiché comme `scenario.outcome.*` dans UX simple.
```

## 14. Contrat Battle reference / Battle outcome

Rappel :

```text
Scene lance Battle.
Battle résout.
Scene interprète.
```

Acquis :

```text
- trainer battle prouvé Level 2 ;
- boss trainer-like prouvé Level 2 ;
- `startTrainerBattle` existant ;
- `ScenarioRuntimeEffectType.battle` ;
- flags `battle:<battleId>:victory/defeat/flee/captured`.
```

Limites :

```text
- static wild scenario réel non prouvé ;
- money reward non prouvé ;
- XP / level-up / learn-move non prouvés ;
- map_battle ne doit pas connaître Narrative Studio.
```

Recommandation Phase 2 :

```text
Contrat minimal de référence battle pour Scene :
- battleId ;
- trainerId ou battle template id ;
- npcEntityId si trainer-like ;
- outcomes supportés en V0 : victory / defeat ;
- mapping Scene branch / Fact / Step pour chaque outcome.
```

Reporter :

```text
capture, flee, static wild authoring, money, XP, level-up, reward model unifié.
```

## 15. Contrat Fact

Rappel :

```text
Fact = vérité lisible.
```

Stockages possibles existants :

```text
- `storyFlags.activeFlags` ;
- `completedStepIds` ;
- Bag item ownership ;
- trainer state ;
- battle outcome flags ;
- variables.
```

Question centrale :

```text
FactRegistry ou FactPresentationLayer ?
```

Recommandation :

```text
Commencer par FactDescriptor / FactPresentationLayer minimal, pas un gros
FactRegistry obligatoire.
```

Raison :

```text
Le GameState porte déjà plusieurs vérités. Un Fact stocké en double peut
créer incohérence, migrations inutiles et sur-modélisation.
```

Contrat minimal recommandé :

```text
- id technique futur ou référence storage ;
- label humain ;
- description ;
- type : stored / derived / presentation ;
- source de vérité ;
- source d’écriture attendue ;
- consumers attendus ;
- diagnostic exposure.
```

Consumers :

```text
map_editor pickers, Validator, World Rules, Event/Scene conditions,
future migrations/persistence.
```

## 16. Contrat World Rule

Rappel :

```text
World Rule = projection passive.
```

Ce qui existe :

```text
- `MapEntityRuntimePredicate` ;
- `MapEntityNpcVisibilityRule` ;
- `MapEntityConditionalDialogue` ;
- `MapEntityRuntimePredicateEvaluator` ;
- Step Studio world presence metadata.
```

Question :

```text
Créer WorldRuleRegistry ou adapter les predicates existants ?
```

Recommandation :

```text
Adapter d’abord les predicates existants via un WorldRule Authoring /
Diagnostic View.
```

Contrat minimal :

```text
- rule label ;
- condition lisible ;
- target map/entity/dialogue/item/door future ;
- projection type ;
- fallback ;
- priority/conflict policy si nécessaire ;
- source predicate existante.
```

Diagnostics :

```text
- World Rule sans condition ;
- condition impossible ;
- target absent ;
- conflit de règles ;
- règle utilisée comme Event ;
- règle qui écrit Fact/Step.
```

## 17. Contrat Validator diagnostics

Le validator existe déjà en V0 et diagnostique notamment graphes, dialogues, trainers, outcomes, flags et steps. Phase 2 doit l’étendre par domaines sans en faire un auto-fixer.

Diagnostics recommandés :

| Domaine | Diagnostics Phase 2 |
|---|---|
| Storyline / Step | Storyline sans step, Step jamais activable, Step inconnu, sideQuest sans entrée. |
| Event | Source absente, target Scene absente, source map/entity/trigger inconnue. |
| Scene | Scene sans source, Scene unreachable, Scene sans fin, Scene qui mélange rôles interdits. |
| Yarn outcome | Outcome émis non géré, consommé jamais émis, durable sans Fact. |
| Battle outcome | victory/defeat non gérés, battle ref absente, trainer absent. |
| Fact | Fact sans label humain, lu jamais écrit, écrit jamais lu, dupliqué. |
| World Rule | Target absent, conflit, règle sans condition, règle utilisée comme Event. |
| References | Picker source cassée, id brut orphelin, map/entity/dialogue/scenario absent. |
| Side quest | Disponible sans entry Event, terminée sans Step/Fact de résolution. |

Règle :

```text
Validator diagnostique.
Validator ne corrige pas automatiquement.
```

## 18. Contrat Reference Registry / Picker Sources

P1-06 a identifié les pickers. Phase 2 doit leur fournir des sources de données pures.

Important :

```text
Picker source ≠ UI widget.
```

Sources recommandées :

| Picker source | Source de vérité probable | Consumer |
|---|---|---|
| Storyline picker | Storyline descriptors / global story metadata | map_editor Phase 4, validator |
| Chapter picker | Global Story metadata / descriptors | map_editor Phase 4 |
| Story Step picker | Step descriptors / completedStepIds mapping | map_editor, validator |
| Scene picker | ScenarioAsset adapter | map_editor, validator |
| Yarn outcome picker | declared/emitted/consumed outcomes adapter | map_editor, validator |
| Battle picker | trainers + battle refs | map_editor, runtime bridge |
| Fact picker | FactPresentationLayer | map_editor, validator, world rules |
| World Rule target picker | maps/entities/dialogues/project refs | map_editor, validator |
| Map / Entity picker | ProjectManifest maps + MapData entities | map_editor, validator |

## 19. Persistence, JSON et migration — stratégie proposée

Questions à traiter avant tout modèle persistant :

```text
Quels contrats doivent être persistés ?
Quels contrats peuvent rester dérivés ?
Quels contrats nécessitent JSON ?
Quels contrats peuvent être read-only/adapters ?
Quand build_runner serait nécessaire ?
Quels risques de migration ProjectManifest existent ?
```

Recommandation :

```text
Ne pas modifier ProjectManifest trop tôt.
Ne pas ajouter de champs persistants avant d’avoir validé consumers,
migrations et backward compatibility.
Distinguer contrat domaine et contrat JSON.
```

Contrats probablement dérivés/read-only en premier :

```text
- Scene adapter ;
- Outcome reference view ;
- Fact presentation mapping vers états existants ;
- World Rule predicate adapter ;
- Reference picker sources.
```

Contrats potentiellement persistants plus tard :

```text
- Storyline / Step descriptors si metadata actuelle devient insuffisante ;
- FactDescriptor si label humain doit survivre hors dérivation ;
- WorldRule authoring contract si predicates existants ne couvrent pas les targets.
```

Build runner serait nécessaire uniquement si Phase 2 décide de nouveaux modèles Freezed/JsonSerializable. P1-07 recommande de repousser cette décision jusqu’à l’audit P2-00/P2-01.

## 20. Package boundaries proposés

Proposition :

```text
map_core
→ value objects purs, contracts, diagnostics, read models,
  registry definitions si nécessaires.

map_gameplay
→ résolution pure GameState / conditions / mutations si nécessaire.

map_runtime
→ adapters runtime, execution bridge, Flame integration plus tard.

map_editor
→ workflows auteur, pickers UI, panels plus tard.

map_battle
→ reste indépendant du Narrative Studio.
```

Interdictions à préserver :

```text
map_battle ne dépend pas de Narrative Studio.
map_core ne dépend pas de Flutter.
map_gameplay ne dépend pas de UI/Flame.
map_editor ne devient pas source de vérité domaine.
gameplay rules ne se cachent pas dans Flame.
```

## 21. Proposition de lots Phase 2

Ne pas créer `road_map_phase_2.md` dans P1-07. Les lots ci-dessous sont une proposition pour décision utilisateur/checkpoint.

| Lot proposé | Objectif | Fichiers probables à auditer | Risque | Tests probables | Non-objectifs | Dépendances |
|---|---|---|---|---|---|---|
| P2-00 — Phase 2 Roadmap Bootstrap / Contract Audit | Valider le découpage Phase 2 et l’inventaire exact. | `reports/roadmap/phase_1/*`, `packages/map_core/lib`, `packages/map_editor/lib/src/features/narrative` | Démarrer trop large. | Aucun ou docs check. | Pas de code domaine. | P1-CHECKPOINT-01. |
| P2-01 — Existing Narrative Domain Inventory | Inventorier modèles, metadata, validators, runtime sources. | `scenario_asset.dart`, `project_manifest.dart`, `narrative_validator.dart`, Step/Global Story authoring | Sous-estimer metadata editor. | Tests d’inventaire si read models créés. | Pas de nouveau modèle persistant. | P2-00. |
| P2-02 — Story Step Descriptor Decision | Décider descriptor vs metadata pour Storyline/Chapter/Step. | `step_studio_authoring.dart`, `global_story_studio_authoring.dart`, `save_data.dart` | Dupliquer `completedStepIds`. | Tests pure Dart descriptor/diagnostics. | Pas de Quest Engine/Journal. | P2-01. |
| P2-03 — Event Authoring Source Contract | Formaliser source Event auteur et diagnostics. | `scenario_runtime_models.dart`, `scenario_runtime_executor.dart`, `scenario_asset.dart` | Dupliquer runtime source events. | Tests validation Event refs. | Pas de runtime Flame. | P2-01. |
| P2-04 — Scene / ScenarioAsset Adapter Contract | Stabiliser Scene comme vue produit sur ScenarioAsset. | `scenario_asset.dart`, `project_scenario_use_cases.dart`, `narrative_workspace_projection.dart` | Casser ScenarioAsset. | Tests adapter/read model. | Pas de Scene Builder complet. | P2-01. |
| P2-05 — Outcome Reference Contracts | Rendre Yarn/outcomes sélectionnables et diagnosticables. | `scenario_asset.dart`, `narrative_validator.dart`, `narrative_workspace_projection.dart` | Créer un registry trop tôt. | Tests emitted/consumed/declared. | Pas de Yarn parser complet. | P2-04. |
| P2-06 — Battle Reference / Outcome Contract | Minimal victory/defeat, trainer-like. | `project_trainer.dart`, `scenario_battle_outcome_flags.dart`, executor | Aspirer static wild/rewards. | Tests refs battle/trainer/outcomes. | Pas money/XP/static wild. | P2-04. |
| P2-07 — Fact Descriptor / Presentation Layer | Labels humains pour truths existantes. | `game_state.dart`, `save_data.dart`, `game_state_mutations.dart`, validator | Dupliquer state. | Tests mapping flag/step/bag derived. | Pas FactRegistry lourd obligatoire. | P2-02/P2-05. |
| P2-08 — World Rule Predicate Adapter Contract | Formaliser projections passives sur predicates. | `map_entity_payloads.dart`, `map_entity_runtime_predicate_evaluator.dart`, Step world presence runtime | Registry prématuré. | Tests target/condition/diagnostics. | Pas WorldRule qui déclenche. | P2-07. |
| P2-09 — Narrative Validator Diagnostic Expansion | Ajouter diagnostics domaine prioritaires. | `narrative_validator.dart`, `validators.dart` | Trop de diagnostics non actionnables. | Tests par diagnostic. | Pas auto-fix. | P2-02 à P2-08. |
| P2-10 — Reference Picker Read Models | Sources pures pour pickers Phase 4. | `ProjectManifest`, MapData, adapters précédents | Confondre read model et widget. | Tests read models tri/stabilité. | Pas UI Flutter. | P2-09. |
| P2-CHECKPOINT — Phase 2 Closure | Vérifier contrats, boundaries, diagnostics, reports. | Tous rapports Phase 2 | Clôturer avec gaps cachés. | Commandes ciblées selon changements. | Pas Phase 3 démarrée. | P2-10. |

## 22. Lots explicitement reportés

| Élément reporté | Report recommandé |
|---|---|
| UI moderne / premium | Phase 7 UI finale |
| Scene Builder complet | Phase 7 ou après authoring minimal |
| Cinematic Builder complet | Phase 7 ou lot spécialisé |
| Quest Journal | Phase 7 / UI future |
| Quest Engine complet | Refuser maintenant ; reconsidérer après preuve consumers |
| Reward Model unifié | Phase 5 gameplay gaps |
| Money / XP / level-up post battle | Phase 5 gameplay gaps |
| Static wild encounter authoring | Phase 5 gameplay gaps |
| Door/Warp Engine complet | Phase 3 runtime/disk ou Phase 5 selon priorité |
| PlayableMapGame Golden Slice complet | Phase 3 runtime validation |
| Projet disque Selbrume complet | Phase 6 Selbrume Golden Slice |
| UI pickers Flutter | Phase 4 authoring minimal |

## 23. Critères de sortie de Phase 2

Phase 2 peut être considérée terminée si :

```text
- les contrats domaine nécessaires au Narrative Studio sont créés,
  adaptés ou explicitement reportés ;
- les diagnostics essentiels existent ou sont reportés avec justification ;
- les pickers Phase 4 ont des sources de données propres ;
- les contrats n’ont pas cassé les package boundaries ;
- les modèles persistants éventuels ont une justification claire ;
- aucune migration ProjectManifest inutile n’a été introduite ;
- aucun contenu final Selbrume n’a été créé sans décision explicite ;
- la Phase 3 peut valider runtime/disk sur une base stable.
```

## 24. Mapping Selbrume sur les contrats Phase 2

Mapping conceptuel, sans contenu final créé :

| Élément Selbrume conceptuel | Contrat Phase 2 proposé |
|---|---|
| Storyline Les Brumes de Selbrume | Storyline descriptor ou metadata légère |
| Chapter Le port | Chapter descriptor/metadata optionnel |
| Step Parler à Lysa au port | Story Step descriptor |
| Event interaction Lysa | Event Authoring Source Contract |
| Scene Rencontre rival | Scene / ScenarioAsset Adapter |
| Cinematic entrée du rival | CinematicRef / CutsceneRef minimal |
| Yarn `rival_intro` | Yarn Outcome Reference Contract |
| Battle Rival | Battle Reference Contract |
| Outcome victory/defeat | Battle Outcome Contract minimal |
| Fact rival battu | Fact descriptor/presentation |
| World Rule dialogue Lysa post-combat | World Rule / Predicate Adapter |
| Side quest Soline | Storyline type sideQuest |
| Validator | Diagnostics contracts |

Rappel :

```text
Ce mapping est conceptuel.
Aucun contenu Selbrume final n’est créé par P1-07.
```

## 25. Risques, alternatives et garde-fous

| Risque | Garde-fou |
|---|---|
| Sur-modélisation | Audit P2-01 avant création ; pas de modèle sans consumer. |
| Dupliquer l’état existant | FactDescriptor peut être derived/presentation ; ne pas stocker deux fois. |
| Casser ScenarioAsset | Commencer par adapter Scene, pas wrapper persistant. |
| Quest Engine prématuré | Side quest reste Storyline secondaire ; Quest Engine refusé en Phase 2. |
| Fact comme flag brut avec label cosmétique | Exiger label humain, source de vérité, consumers et diagnostics. |
| UI avant contrats | Phase 2 domaine/diagnostics/read models ; UI Phase 4/7. |
| Migrations ProjectManifest trop tôt | Séparer domaine et JSON ; migration seulement avec consumers/migration path. |
| Battle devient moteur narratif | Battle résout ; Scene interprète et écrit Facts/Steps. |
| World Rule devient Event | World Rule projette ; Event déclenche. |
| Validator trop magique | Validator diagnostique ; pas d’auto-correction. |

## 26. Mise à jour de road_map_phase_1.md

Mise à jour effectuée :

```text
P1-07 : ✅ terminé
P1-CHECKPOINT-01 : 🔜 prochain lot exact
```

Résumé court ajouté :

```text
P1-07 propose une Phase 2 bornée autour de contrats domaine minimaux,
diagnostics, adapters/read models et picker sources, sans créer de modèles,
JSON, UI ni contenu Selbrume.
```

Fichiers créés/modifiés :

```text
Créé   : reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
Modifié: MVP Selbrume/road_map_phase_1.md
```

Décisions utilisateur nouvelles identifiées :

```text
Aucune décision nouvelle bloquante n’a été prise par P1-07.
Les décisions à valider sont listées en section 27.
```

Changements de périmètre :

```text
Aucun.
```

## 27. Décisions à valider par l’utilisateur

Décisions non bloquantes à valider avant ou pendant P1-CHECKPOINT-01 :

```text
- Phase 2 doit-elle commencer par audit des modèles existants ou par création
  directe de nouveaux contrats ?
- Scene doit-elle être le nom produit de ScenarioAsset, un wrapper, ou un
  adapter/read model ?
- Faut-il créer un FactRegistry ou commencer par une Fact Presentation Layer ?
- Faut-il créer un WorldRuleRegistry ou adapter les predicates existants ?
- Storyline/Chapter doivent-ils devenir persistants dès Phase 2 ?
- Le Story Step Descriptor est-il obligatoire en V0 ou peut-il rester metadata ?
- Quels lots Phase 2 sont prioritaires ?
- Quels éléments doivent être explicitement reportés à Phase 4 ou Phase 5 ?
- Battle outcomes V0 doivent-ils imposer victory/defeat comme branches
  obligatoires ?
- Les rewards doivent-ils rester hors Phase 2 sauf diagnostics de référence ?
```

## 28. Evidence Pack

### 28.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 28.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/gameplay/audit/narrative_studio_product_model_v0.md
reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md
reports/gameplay/audit/sel_b2_battle_from_scene.md
reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md
reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md
reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart
packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart
packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
```

### 28.3 Fichiers créés

```text
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
```

### 28.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_1.md
```

### 28.5 Commandes exécutées

```text
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
git status --short --untracked-files=all
sed -n '1,280p' "MVP Selbrume/road_map_global.md"
sed -n '1,620p' "MVP Selbrume/road_map_phase_1.md"
sed -n '1,300p' reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
sed -n '1,300p' reports/roadmap/roadmap_global_00_master_phase_roadmap_bootstrap.md
sed -n '1,320p' reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md
sed -n '1,520p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
sed -n '1,520p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '1,560p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
sed -n '1,620p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '1,660p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
sed -n '1,720p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
sed -n '1,360p' "MVP Selbrume/road_map.md" && sed -n '1,360p' "MVP Selbrume/narrative_studio.md" && sed -n '1,300p' "MVP Selbrume/selbrume.md"
sed -n '520,1100p' reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md && sed -n '520,1100p' reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
sed -n '560,1150p' reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md && sed -n '620,1150p' reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
sed -n '660,1250p' reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md && sed -n '720,1500p' reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
sed -n '360,820p' "MVP Selbrume/narrative_studio.md" && sed -n '300,900p' "MVP Selbrume/selbrume.md" && sed -n '360,760p' "MVP Selbrume/road_map.md"
sed -n '1,360p' reports/gameplay/audit/narrative_studio_product_model_v0.md && sed -n '1,360p' reports/gameplay/audit/sel_a2_event_scene_outcome_fact_contract.md && sed -n '1,320p' reports/gameplay/audit/sel_b2_battle_from_scene.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_08_npc_interaction_scene_authoring_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_09_yarn_outcome_scene_branch_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_10_world_rules_conditional_presence_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_11_trainer_battle_authoring_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_14_item_pickup_give_item_authoring_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_15_key_item_door_gate_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_17_static_encounter_boss_battle_readiness.md && sed -n '1,360p' reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md && sed -n '1,420p' reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
find packages/map_core/lib -maxdepth 3 -type f | sort
find packages/map_gameplay/lib -maxdepth 3 -type f | sort
find packages/map_runtime/lib -maxdepth 4 -type f | sort
find packages/map_editor/lib -maxdepth 4 -type f | sort
rg -n "class ScenarioAsset|ScenarioAsset|ScenarioRuntimeSourceEvent|entityInteract|triggerEnter|mapEnter|outcomeReceived|completedStepIds|storyFlags|MapEntityRuntimePredicateEvaluator|NarrativeValidator|diagnoseNarrativeProject|ProjectManifest|ScenarioNode|ScenarioRuntimeEffectType|startTrainerBattle|WorldRule|StoryStep|GlobalStory|Chapter|Fact|Predicate|giveItem|battleId|sourceOutcome" packages/map_core/lib packages/map_gameplay/lib packages/map_runtime/lib packages/map_editor/lib --type dart
sed -n '1,260p' packages/map_core/lib/src/models/scenario_asset.dart && sed -n '1,220p' packages/map_core/lib/src/models/project_manifest.dart && sed -n '1,180p' packages/map_core/lib/src/models/script_conditions.dart
sed -n '1,220p' packages/map_core/lib/src/models/game_state.dart && sed -n '1,340p' packages/map_core/lib/src/models/save_data.dart && sed -n '1,180p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart && sed -n '1,180p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart && sed -n '1,140p' packages/map_runtime/lib/src/application/cutscene_runtime_models.dart
sed -n '1,260p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '1,180p' packages/map_core/lib/src/validation/validators.dart
rg -n "const String kScenario|case kScenario|sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|emitOutcome|startTrainerBattle|giveItem|completeStep|moveCharacter|followCharacter|faceCharacter|transitionMap|ScenarioRuntimeEffectType.battle|scenarioOutcomeFlagName|_findMatchingSourceNode|_pickConditionNextNodeId|dispatchContinuation" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
sed -n '1,180p' packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart && sed -n '1,180p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart && sed -n '1,220p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
sed -n '1,320p' packages/map_gameplay/lib/src/game_state_mutations.dart && sed -n '1,160p' packages/map_gameplay/lib/src/script_condition_evaluator.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/global_story_studio_workspace.dart && sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/step_studio_workspace.dart && sed -n '1,180p' packages/map_editor/lib/src/ui/panels/narrative_library_panel.dart
sed -n '1,320p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
sed -n '1,320p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '1,320p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
rg -n "Lot courant|Prochain lot exact|P1-06|P1-07|P1-CHECKPOINT|Historique|journal|Mise à jour|Phase 1|prochain" "MVP Selbrume/road_map_phase_1.md"
sed -n '1,70p' "MVP Selbrume/road_map_phase_1.md" && sed -n '300,420p' "MVP Selbrume/road_map_phase_1.md" && sed -n '470,570p' "MVP Selbrume/road_map_phase_1.md"
git diff --check
git diff --no-index --check /dev/null reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md || true
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff -- "MVP Selbrume/road_map_phase_1.md"
git diff -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages examples/playable_runtime_host
test ! -e "MVP Selbrume/road_map_phase_2.md" && printf 'road_map_phase_2.md absent\n'
wc -l reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
find reports/roadmap/phase_1 -maxdepth 1 -type f | sort
find reports/gameplay/ns_gs -maxdepth 1 -type f | sort
perl -pi -e 's/[ \t]+$//' reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
```

### 28.6 git diff --check

```text

```

### 28.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_1.md | 44 ++++++++++++++++++++++++++++------------
 1 file changed, 31 insertions(+), 13 deletions(-)
```

### 28.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_1.md
```

### 28.9 git status final

```text
 M "MVP Selbrume/road_map_phase_1.md"
?? reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
```

### 28.10 Tests / analyze

```text
Non exécutés — P1-07 est documentaire et ne modifie aucun code.
```

### 28.11 Contrôles supplémentaires autorisés

```text
git diff -- "MVP Selbrume/road_map_global.md"
Sortie exacte :

git diff --name-only -- packages examples/playable_runtime_host
Sortie exacte :

test ! -e "MVP Selbrume/road_map_phase_2.md" && printf 'road_map_phase_2.md absent\n'
Sortie exacte :
road_map_phase_2.md absent

wc -l reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md "MVP Selbrume/road_map_phase_1.md" "MVP Selbrume/road_map_global.md"
Sortie exacte :
    1444 reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
     570 MVP Selbrume/road_map_phase_1.md
     638 MVP Selbrume/road_map_global.md
    2652 total
```

### 28.12 Diff complet de road_map_phase_1.md

```diff
diff --git a/MVP Selbrume/road_map_phase_1.md b/MVP Selbrume/road_map_phase_1.md
index 2dbbbee4..16605e61 100644
--- a/MVP Selbrume/road_map_phase_1.md
+++ b/MVP Selbrume/road_map_phase_1.md
@@ -6,9 +6,9 @@ Phase 1 — Canonical Product Model / Narrative Studio Foundations

 Statut : 🔜 En préparation

-Lot courant : P1-06 — No-code Workflow Specification
+Lot courant : P1-07 — Phase 2 Domain Contract Proposal

-Prochain lot exact après P1-06 : P1-07 — Phase 2 Domain Contract Proposal
+Prochain lot exact après P1-07 : P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 Suivi des lots :

@@ -19,8 +19,8 @@ Suivi des lots :
 - ✅ P1-04 — Storyline / Chapter / Story Step Structure
 - ✅ P1-05 — Selbrume Reference Grammar Mapping
 - ✅ P1-06 — No-code Workflow Specification
-- 🔜 P1-07 — Phase 2 Domain Contract Proposal
-- P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+- ✅ P1-07 — Phase 2 Domain Contract Proposal
+- 🔜 P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 P1-00 : ✅ terminé

@@ -36,7 +36,9 @@ P1-05 : ✅ terminé

 P1-06 : ✅ terminé

-P1-07 : 🔜 prochain lot exact
+P1-07 : ✅ terminé
+
+P1-CHECKPOINT-01 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 1

@@ -341,11 +343,11 @@ Critères de validation :
 - le validator est placé dans le flux auteur ;
 - les dépendances Phase 2 / Phase 4 sont séparées.

-### 🔜 P1-07 — Phase 2 Domain Contract Proposal
+### ✅ P1-07 — Phase 2 Domain Contract Proposal

 Objectif :
 Transformer les décisions Phase 1 en proposition de lots Phase 2.
-Lister les modèles map_core à créer, adapter ou reporter.
+Lister les contrats domaine à créer, adapter ou reporter.

 Type :
 Documentaire / proposition de contrats domaine.
@@ -369,7 +371,7 @@ Critères de validation :
 - les risques de migration sont listés ;
 - les modèles à reporter sont explicitement justifiés.

-### P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision
+### 🔜 P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 Objectif :
 Vérifier que Phase 1 a fermé les ambiguïtés et recommander la roadmap détaillée
@@ -400,14 +402,16 @@ Critères de validation :

 ## 10. Prochain lot exact

-P1-07 — Phase 2 Domain Contract Proposal
+P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

 Objectif du prochain lot :
-Transformer les décisions Phase 1 en proposition de lots Phase 2 et lister les
-contrats domaine à créer, adapter ou reporter.
+Auditer tous les livrables Phase 1, vérifier les ambiguïtés restantes,
+décider la transition vers Phase 2 et recommander ou préparer la roadmap de
+phase suivante.

-P1-07 ne doit pas créer de code, de modèles `map_core`, de schemas JSON, de
-fixtures Selbrume finales ou de `project.json`.
+P1-CHECKPOINT-01 est le seul lot Phase 1 autorisé à décider la transition de
+phase. Il ne doit pas démarrer Phase 2 ni créer de contenu Selbrume final sans
+validation utilisateur.

 ## 11. Critères de sortie de Phase 1

@@ -550,3 +554,17 @@ P1-CHECKPOINT-01 devra aussi mettre à jour
   Décisions utilisateur nouvelles : aucune.
   Changements de périmètre : aucun.
   Prochain lot exact fixé à P1-07 — Phase 2 Domain Contract Proposal.
+- 2026-05-24 — P1-07 — Phase 2 Domain Contract Proposal terminé.
+  Résultat : proposition bornée de contrats Phase 2, avec distinction
+  créer / adapter / reporter, consumers explicites, stratégie prudente
+  persistence / JSON / migration, package boundaries et lots Phase 2 proposés
+  sans les exécuter.
+  Fichiers créés : `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`.
+  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
+  Commandes exécutées : lectures Markdown ciblées, inspection read-only
+  `packages/...`, `find`, `rg`, `git status --short --untracked-files=all`,
+  `git diff --check`, `git diff --stat`, `git diff --name-only`,
+  `git diff --no-index --check`, `wc -l`.
+  Décisions utilisateur nouvelles : aucune.
+  Changements de périmètre : aucun.
+  Prochain lot exact fixé à P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision.
```

### 28.13 Contrôle no-index du rapport P1-07

```text

```

## 29. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

```text
Oui : rapport P1-07 créé et road_map_phase_1.md mise à jour uniquement.
```

Le rapport P1-07 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md.
```

road_map_phase_1.md a-t-elle été mise à jour ?

```text
Oui.
```

road_map_global.md est-elle restée intacte ?

```text
Oui : `git diff -- "MVP Selbrume/road_map_global.md"` n’a produit aucune sortie.
```

Aucun code n’a-t-il été modifié ?

```text
Oui : `git diff --name-only -- packages examples/playable_runtime_host` n’a produit aucune sortie.
```

Aucun test/analyze Dart/Flutter n’a-t-il été lancé inutilement ?

```text
Oui : aucun test/analyze Dart/Flutter lancé.
```

P1-CHECKPOINT-01 n’a-t-il pas été commencé ?

```text
Oui : seulement mentionné comme prochain lot exact.
```

road_map_phase_2.md n’a-t-elle pas été créée ?

```text
Oui : le contrôle a retourné `road_map_phase_2.md absent`.
```

Selbrume est-il resté une référence conceptuelle seulement ?

```text
Oui.
```

Aucun modèle map_core n’a-t-il été créé ?

```text
Oui.
```

Aucun schéma JSON n’a-t-il été créé ?

```text
Oui.
```

La proposition Phase 2 est-elle bornée et non infinie ?

```text
Oui : lots Phase 2 limités, avec checkpoint et reports explicites.
```

Les risques de sur-modélisation sont-ils traités ?

```text
Oui : audit d’abord, pas de modèle sans consumer, adapters/read models avant persistence.
```

Les reports hors Phase 2 sont-ils explicites ?

```text
Oui : section 22.
```

Ambiguïtés restantes :

```text
- statut exact Scene = ScenarioAsset vs adapter vs wrapper ;
- besoin réel d’un FactRegistry ;
- besoin réel d’un WorldRuleRegistry ;
- persistence Storyline/Chapter/Step ;
- priorité des lots Phase 2.
```

### Regard critique sur le prompt

Le prompt est strict et utile : il empêche de glisser vers l’implémentation Phase 2. L’ambiguïté principale vient de la demande de "proposer une roadmap Phase 2" tout en interdisant de créer `road_map_phase_2.md`. La résolution retenue est de proposer les lots dans ce rapport uniquement, sans créer de roadmap vivante.

Autre point de vigilance : plusieurs concepts existent déjà partiellement dans des metadata editor ou read models. P1-07 recommande donc une Phase 2 qui commence par inventaire et décisions d’adaptation plutôt que création mécanique de nouveaux modèles.
