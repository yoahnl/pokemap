# P2-07 — Fact Descriptor / Presentation Layer

## 1. Résumé exécutif

P2-07 reste design-first et ne produit aucun code. Le lot décide que les Facts
doivent être une présentation lisible de vérités techniques existantes, et non
une nouvelle source de vérité.

La vérité technique observée est déjà portée par :

- `GameState.storyFlags.activeFlags` ;
- `SaveData.progression.storyFlags`, migré/mergé vers `GameState.storyFlags` au
  chargement/sauvegarde ;
- `GameState.progression.completedStepIds` ;
- `GameState.progression.completedCutsceneIds` ;
- `GameState.scriptVariables.values` ;
- `GameState.consumedEventIds` ;
- `GameState.bag`, `party` et `trainerProfile.money` pour des vérités gameplay ;
- flags techniques `scenario.outcome.*` ;
- flags techniques `battle:<battleId>:<suffix>` ;
- flags runtime `trainer_defeated:<trainerId>`.

Décision recommandée :

- ne pas créer de modèle persistant ;
- ne pas modifier `ProjectManifest` ;
- ne pas modifier `GameState` ou `SaveData` ;
- ne pas créer de `FactRegistry` ;
- ne pas dupliquer `storyFlags` ou `completedStepIds` ;
- ne pas transformer automatiquement outcome ou battle outcome en Fact ;
- garder World Rule séparé pour P2-08 ;
- recommander une future `FactPresentationReadModel` non persistante, dérivée
  des sources techniques et des producers/consumers observés, si P2-09/P2-10 le
  justifient.

Le prochain lot exact est :

```text
P2-08 — World Rule Predicate Adapter Contract
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports demandés ;
- audit ciblé des sources de vérité techniques ;
- audit des actions qui écrivent ces vérités ;
- audit des conditions/predicates qui lisent ces vérités ;
- comparaison des options Fact existant / presentation layer / registry ;
- décision d'implémentation P2-07 ;
- proposition de contrat conceptuel non implémenté ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- modèle `map_core` ;
- `FactRegistry` persistant ;
- modification `GameState` ;
- modification `SaveData` ;
- modification `ProjectManifest` ;
- JSON, migration, Freezed, JsonSerializable, build_runner ;
- UI ;
- World Rule adapter P2-08 ;
- diagnostics P2-09 implémentés ;
- picker read models P2-10 implémentés ;
- Selbrume final.

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` : phase globale et reports.
- `MVP Selbrume/road_map_phase_2.md` : statut Phase 2, P2-07 et P2-08.
- `MVP Selbrume/road_map_phase_1.md` : clôture Phase 1.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
  : cadrage audit-first.
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` :
  inventaire technique initial.
- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
  : décision de ne pas dupliquer `completedStepIds`.
- `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` : Event
  comme déclencheur.
- `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md` :
  Scene comme orchestration dérivée de `ScenarioAsset`.
- `reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md` : outcome
  non transformé automatiquement en Fact.
- `reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md` : battle
  outcome non transformé automatiquement en Fact.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  : concepts figés.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` :
  proposition FactDescriptor / Presentation.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` :
  besoins auteur.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` :
  grammaire Fact / World Rule.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` :
  modèle produit canonique.

Code lu en lecture seule :

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/lib/src/models/script_conditions.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_gameplay/lib/src/game_state_mutations.dart`
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/story_flags_manager.dart`
- `packages/map_runtime/lib/src/application/scenario_conditions.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`

## 4. Rappel Phase 1 / P2-01 à P2-06

Phase 1 a figé :

```text
Fact = vérité lisible.
World Rule = projection passive.
Scene écrit les conséquences durables.
World Rule ne déclenche pas de Scene.
Fact ne doit pas être exposé comme flag technique.
Validator diagnostique.
```

P2-01 a confirmé que les vérités techniques existent déjà dans `GameState`,
`SaveData`, `ScenarioAsset`, les conditions, les predicates runtime et les flags
runtime.

P2-02 a décidé que `completedStepIds` reste la source de completion et que les
Storyline / Chapter / Story Step ne deviennent pas persistants maintenant.

P2-05 a décidé que `scenario.outcome.*` reste technique et que les outcomes ne
deviennent pas automatiquement Facts.

P2-06 a décidé que `battle:<battleId>:victory`,
`battle:<battleId>:defeat` et `trainer_defeated:<trainerId>` restent des vérités
techniques, sans promotion automatique en Fact.

P2-07 doit donc nommer et présenter sans recopier.

## 5. Problème à résoudre

L'auteur a besoin de labels humains et de relations source/consumer :

- "Mael a été rencontré" ;
- "Step parler à Lysa terminé" ;
- "Rival battu au port" ;
- "Outcome rival_intro.accepted reçu" ;
- "Soline side quest disponible".

Le repo, lui, porte surtout :

- des flags techniques ;
- des ids de steps ;
- des outcomes ;
- des variables ;
- des predicates ;
- des états gameplay.

Le problème P2-07 est de relier les deux niveaux sans créer une deuxième base
de vérité.

## 6. Inventaire des sources techniques de vérité

| Source | Vérité portée | Stocké / dérivé | Peut être présenté comme Fact ? | Garde-fou |
|---|---|---|---|---|
| `GameState.storyFlags.activeFlags` | Flags booléens narratifs/runtime | Stocké runtime | Oui, si label/source/consumer clair | Ne pas exposer tous les flags en UX principale |
| `SaveData.progression.storyFlags` | Flags persistés legacy/save | Stocké save | Oui via migration vers `GameState.storyFlags` | Ne pas créer une troisième liste |
| `GameState.progression.completedStepIds` | Steps complétés | Stocké runtime/save | Oui pour "step terminé" | Ne jamais dupliquer |
| `GameState.progression.completedCutsceneIds` | Cutscenes/scénarios complétés | Stocké runtime/save | Possible si consumer clair | Ne pas confondre avec Scene complète |
| `GameState.scriptVariables.values` | Variables bool/int/string | Stocké runtime | Rarement en V0, plutôt avancé/debug | Ne pas les rebaptiser Facts sans usage |
| `GameState.consumedEventIds` | Events consommés | Stocké runtime | Possible pour pickups/interactions | Garder le lien Event |
| `GameState.bag` | Possession d'items | Stocké gameplay | Fact dérivé possible | Ne pas créer Reward Model |
| `GameState.party` | Pokémon possédés/état équipe | Stocké gameplay | Fact dérivé possible plus tard | Hors Fact V0 sauf besoin clair |
| `TrainerProfile.money` | Argent | Stocké gameplay | Non P2-07 principal | Phase 5 rewards/money |
| `scenario.outcome.*` | Outcome scénario persistant | Flag technique | Présentation possible | Pas Fact automatique |
| `battle:<battleId>:suffix` | Outcome battle technique | Flag technique | Présentation possible | Pas Fact automatique |
| `trainer_defeated:<trainerId>` | Trainer battu | Flag runtime | Présentation possible | Distinguer de battle outcome |

Observation importante :

- `game_state_persistence.dart` migre les `SaveData.progression.storyFlags` vers
  `GameState.storyFlags.activeFlags` au chargement et fusionne les deux au
  moment de reconstruire `SaveData`.
- Cela renforce l'interdiction de créer un stockage Fact supplémentaire.

## 7. Inventaire des actions qui produisent des vérités

Actions scénario/runtime observées :

- `setFlag` écrit dans `GameState.storyFlags.activeFlags` via
  `StoryFlagsManager.set` / `GameStateMutations.setFlag`.
- `clearFlag` retire un flag via `StoryFlagsManager.clear` /
  `GameStateMutations.clearFlag`.
- `completeStep` écrit dans `GameState.progression.completedStepIds` via
  `GameStateMutations.completeStep`, sans doublon.
- `emitOutcome` écrit un flag `scenario.outcome.<outcomeId>` puis dispatch un
  `ScenarioRuntimeSourceEvent.outcomeReceived`.
- `giveItem` modifie le bag.
- `givePokemon` modifie la party.
- `startTrainerBattle` produit un handoff battle ; le write-back post-battle
  peut marquer `trainer_defeated:<trainerId>` en cas de victoire trainer.

Ce qui peut produire une vérité présentable :

- `setFlag` / `clearFlag`, si le flag porte un sens auteur ;
- `completeStep`, comme completion de jalon ;
- `emitOutcome`, comme résultat de branche, mais pas Fact automatique ;
- `startTrainerBattle`, via outcome battle ou trainer defeated, mais pas Fact
  automatique ;
- `giveItem` / `givePokemon`, plutôt comme Facts dérivés gameplay futurs.

Ce qui doit rester hors Fact V0 principal :

- argent, XP, level-up, rewards ;
- party state détaillé ;
- variables techniques sans label ;
- flags debug ou runtime internes.

## 8. Inventaire des conditions qui lisent des vérités

`ScriptCondition` lit :

- `flagIsSet` ;
- `flagIsUnset` ;
- `variableEquals` ;
- `variableGreaterThan` ;
- `variableLessThan` ;
- `fieldAbilityUnlocked` ;
- `partyHasMove` ;
- `eventIsConsumed` ;
- `playerOnMap`.

`MapEntityRuntimePredicate` lit :

- `storyFlagSet` ;
- `storyFlagUnset` ;
- `stepCompleted` ;
- `stepNotCompleted` ;
- `chapterCompleted` ;
- `chapterNotCompleted` ;
- `cutsceneCompleted` ;
- `cutsceneNotCompleted`.

Interprétation :

- `flagIsSet` / `storyFlagSet` peuvent être présentés comme Facts si un label
  humain existe ;
- `stepCompleted` est une vérité dérivée de `completedStepIds` ;
- `chapterCompleted` est dérivé via l'index Global Story, pas un état stocké
  autonome ;
- `cutsceneCompleted` lit `completedCutsceneIds` ;
- variables, party, playerOnMap et field abilities sont des conditions
  techniques ou gameplay qui peuvent alimenter une présentation avancée, pas un
  Fact auteur principal par défaut.

Garde-fou :

- P2-07 ne crée pas de nouveau DSL de conditions.
- La presentation layer future doit réutiliser `ScriptCondition` et
  `MapEntityRuntimePredicate`.

## 9. Inventaire Validator existant

Diagnostics existants liés aux vérités :

- `flagReadNeverProduced` ;
- `setFlagNeverRead` ;
- `stepReadNeverCompleted` ;
- `completeStepNeverRead` ;
- `sourceOutcomeWithoutMatchingEmitOutcome` ;
- `emitOutcomeWithoutMatchingSourceOutcome`.

Le validator collecte :

- flags produits par `setFlag` ;
- flags lus par `ScriptCondition` et predicates runtime ;
- steps complétés par `completeStep` ;
- steps lus par predicates runtime ;
- outcomes émis / consommés.

Ce qui manque pour une presentation layer Fact :

- flag technique sans label auteur ;
- label auteur sans source technique ;
- Fact présenté mais jamais produit ;
- Fact produit mais jamais consommé ;
- Fact basé sur outcome sans décision explicite ;
- Fact basé sur battle outcome sans décision explicite ;
- Fact dupliquant `completedStepIds` ;
- Fact qui correspond en réalité à une World Rule.

Ces diagnostics appartiennent naturellement à P2-09.

## 10. Relation Outcome / Battle outcome / Fact

Outcome scénario :

- source technique : `declaredOutcomes`, `emitOutcome`, `sourceOutcome`,
  `scenario.outcome.*` ;
- statut P2-07 : peut être présenté, mais ne devient pas Fact automatiquement.

Battle outcome :

- source technique : `battle:<battleId>:victory` /
  `battle:<battleId>:defeat` et autres suffixes techniques hors V0 ;
- statut P2-07 : peut être présenté, mais ne devient pas Fact automatiquement.

Trainer defeated :

- source technique : `trainer_defeated:<trainerId>` ;
- statut P2-07 : bonne candidate pour une présentation Fact si un label humain
  et un consumer existent.

Step completion :

- source technique : `completedStepIds` ;
- statut P2-07 : bonne candidate pour une présentation Fact, sans dupliquer la
  completion.

Règle :

```text
Outcome décrit un résultat de branche.
Battle outcome décrit un résultat de combat.
Fact présente une vérité utile à l'auteur.
```

## 11. Relation Fact / World Rule

World Rule lit des vérités et projette passivement le monde :

- présence d'un NPC ;
- variante de dialogue ;
- visibilité conditionnelle ;
- projection selon flag, step, chapter ou cutscene.

World Rule ne crée pas de Facts.

Fact Presentation peut aider P2-08 en fournissant :

- labels humains pour flags/steps/outcomes ;
- source technique stable ;
- consumers connus ;
- diagnostics de références cassées.

Mais P2-08 doit rester séparé parce qu'un World Rule est une projection
passive, pas une vérité.

## 12. Consumers explicites

| Consumer | Besoin | Immédiat ? | Nécessite persistence ? |
|---|---|---:|---:|
| `NarrativeValidator` | Diagnostiquer flags/steps/facts orphelins | Futur P2-09 | Non |
| `ProjectValidator` | Préserver cohérence technique | Déjà partiel | Non |
| P2-08 World Rule adapter | Afficher ce que les predicates lisent | Oui, conceptuel | Non |
| P2-09 diagnostics | Labels et source/consumer pour diagnostics actionnables | Futur | Non |
| P2-10 picker read models | Lister des vérités lisibles | Futur | Non |
| Phase 4 authoring minimal | Choisir des conditions sans ids bruts | Futur | Non au départ |
| Runtime | Lire `GameState` et conditions | Déjà existant | Non nouveau |

Ces consumers justifient une trajectoire de presentation layer non persistante,
mais pas une implémentation immédiate dans P2-07.

## 13. Options de contrat

### Option A — Garder l'existant + diagnostics futurs

Utiliser uniquement `storyFlags`, `completedStepIds`, conditions, outcomes et
predicates existants.

Avantages :

- aucune migration ;
- aucun risque de duplication ;
- `GameState` reste source of truth ;
- suffisant pour P2-08 conceptuel.

Risques :

- labels auteur absents ;
- pickers futurs encore pauvres ;
- diagnostics restent techniques.

Verdict :

Acceptable maintenant, mais insuffisant pour Phase 4.

### Option B — Fact Presentation Layer / read model non persistant

Créer plus tard une vue produit dérivée des vérités techniques existantes.

Avantages :

- fournit labels humains ;
- sert P2-08, P2-09, P2-10 ;
- garde `GameState` comme source de vérité ;
- permet de distinguer flag, step, outcome, battle outcome et state gameplay.

Risques :

- peut devenir un registry déguisé ;
- peut exposer trop de flags techniques ;
- nécessite des règles de sélection claires.

Verdict :

Trajectoire recommandée, sans code maintenant.

### Option C — Contrat pur minimal dans `map_core`

Créer maintenant ou plus tard un type pur pour représenter un `FactDescriptor`.

Avantages :

- testable ;
- peut stabiliser un vocabulaire commun.

Risques :

- consumer immédiat non codé ;
- risque de figer trop tôt les `sourceKind` ;
- peut encourager un registry prématuré ;
- P2-08/P2-09/P2-10 doivent encore préciser leurs besoins.

Verdict :

Possible plus tard, refusé maintenant.

### Option D — FactRegistry persistant

Créer un registre persistant de Facts.

Risques :

- duplique `GameState` ;
- impose migration ;
- multiplie les sources of truth ;
- peut transformer les flags techniques en contrat utilisateur rigide.

Verdict :

Refusé maintenant.

### Option E — Fusionner Fact et World Rule

Traiter les World Rules comme des Facts ou inversement.

Risques :

- Fact nomme ce qui est vrai ;
- World Rule montre ce que le monde projette ;
- fusionner les deux ferait écrire ou déclencher des comportements au mauvais
  niveau.

Verdict :

Refusé. P2-08 reste séparé.

### Option F — Présenter tous les flags comme Facts

Traiter tous les `storyFlags` comme des Facts auteur.

Risques :

- UX auteur polluée par des clés techniques ;
- labels cosmétiques sans source/consumer ;
- flags runtime ou debug exposés comme langage principal ;
- dette de migration si les flags changent.

Verdict :

Refusé en mode auteur principal. Acceptable seulement en mode debug/diagnostic.

## 14. Matrice comparative

| Option | Complexité | Migration | Risque duplication | Support Validator | Support pickers | Recommandation |
|---|---:|---:|---:|---:|---:|---|
| A — Existant + diagnostics futurs | Faible | Non | Faible | Moyen | Faible | Garder maintenant |
| B — Presentation read model futur | Moyenne | Non | Faible si dérivé | Fort | Fort | Trajectoire principale |
| C — Contrat pur `map_core` | Moyenne | Non | Moyen | Fort | Fort | Plus tard seulement |
| D — `FactRegistry` persistant | Forte | Oui | Fort | Moyen | Moyen | Refuser |
| E — Fusion Fact / World Rule | Moyenne | Possible | Conceptuel fort | Faible | Faible | Refuser |
| F — Tous flags = Facts | Faible | Non | UX fort | Faible | Faible | Refuser auteur |

## 15. Décision d'implémentation P2-07

Verdict :

```text
B — Presentation layer / read model recommandé plus tard : aucun code maintenant.
```

Réponses au gate :

- Un FactDescriptor / Fact Presentation Layer est-il nécessaire maintenant ?
  Conceptuellement oui, mais pas en code maintenant.
- Quels consumers explicites le justifient ? P2-08, P2-09, P2-10, Phase 4
  authoring minimal et diagnostics.
- Peut-il être dérivé de `GameState` / `ScenarioAsset` / metadata sans
  persistence ? Oui.
- Peut-il attendre P2-09 / P2-10 ? Oui, car P2-08 peut décider son adapter sur
  les sources techniques existantes.
- Comment éviter de dupliquer `storyFlags` / `completedStepIds` ? Les Facts
  restent des vues : `technicalKey` + `sourceKind`, jamais une copie d'état.
- Comment éviter de créer un `FactRegistry` ? Ne pas persister de liste canonique
  de Facts ; dériver depuis producers/consumers et metadata auteur.
- Quels diagnostics deviennent possibles ? Labels manquants, sources inconnues,
  Facts jamais produits/lus, promotion automatique d'outcome, duplication step.
- La persistence est-elle nécessaire ? Non.

Conditions C non remplies :

- aucun consumer codé immédiat ;
- P2-08 n'est pas bloqué par l'absence d'un type Dart ;
- P2-09/P2-10 doivent encore prioriser diagnostics et picker sources.

Donc P2-07 ne produit aucun code.

## 16. Contrat conceptuel recommandé

Contrat conceptuel non implémenté :

```text
FactPresentationReadModel
```

Champs conceptuels possibles :

- `factId` ;
- `humanLabel` ;
- `description` ;
- `sourceKind` ;
- `sourceId` ;
- `technicalKey` ;
- `technicalValue` ;
- `isDerived` ;
- `isPersistent` ;
- `producerScenarioIds` ;
- `producerNodeIds` ;
- `consumerScenarioIds` ;
- `consumerNodeIds` ;
- `consumerWorldRuleIds` ;
- `relatedStepIds` ;
- `relatedOutcomeIds` ;
- `relatedBattleIds` ;
- `debugTechnicalLabel` ;
- `diagnostics`.

`sourceKind` conceptuels possibles :

- `storyFlag` ;
- `completedStep` ;
- `completedCutscene` ;
- `scenarioOutcome` ;
- `battleOutcome` ;
- `trainerDefeated` ;
- `scriptVariable` ;
- `itemOwnership` ;
- `partyState` ;
- `consumedEvent` ;
- `derived`.

Règles :

- ce contrat n'est pas créé par P2-07 ;
- il ne duplique pas `GameState` ;
- il ne crée pas de `FactRegistry` ;
- il est dérivé autant que possible ;
- il ne fusionne pas Fact et World Rule ;
- il ne promeut pas automatiquement outcomes ou battle outcomes.

## 17. Diagnostics possibles

Diagnostics déjà existants ou proches :

- `flagReadNeverProduced` ;
- `setFlagNeverRead` ;
- `stepReadNeverCompleted` ;
- `completeStepNeverRead` ;
- `sourceOutcomeWithoutMatchingEmitOutcome` ;
- `emitOutcomeWithoutMatchingSourceOutcome`.

Diagnostics futurs possibles :

- `factPresentationMissingLabel` ;
- `factPresentationSourceUnknown` ;
- `factPresentationSourceDuplicated` ;
- `factPresentationDuplicatesCompletedStep` ;
- `technicalFlagExposedAsAuthorFact` ;
- `scenarioOutcomePromotedToFactWithoutDecision` ;
- `battleOutcomePromotedToFactWithoutDecision` ;
- `factNeverProduced` ;
- `factNeverConsumed` ;
- `worldRuleWritesFact` ;
- `factSourceKindUnsupportedInV0`.

Ces diagnostics sont à traiter en P2-09, pas dans P2-07.

## 18. Impacts sur P2-08 à P2-10

P2-08 — World Rule Predicate Adapter Contract :

- doit réutiliser les mêmes sources techniques ;
- peut consommer les labels Fact conceptuels ;
- ne doit jamais écrire un Fact.

P2-09 — Narrative Validator Diagnostic Expansion :

- doit prioriser labels manquants, sources inconnues, flags techniques exposés,
  Facts jamais produits/lus ;
- doit rester dans le validator existant.

P2-10 — Reference Picker Read Models :

- peut créer des listes lisibles de Facts dérivées ;
- doit garder un mode debug pour les clés techniques ;
- ne doit pas créer de widgets UI.

## 19. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Créer un `FactRegistry` prématuré | Presentation read model dérivé, non persistant. |
| Dupliquer `completedStepIds` | Completion source = `GameState.progression.completedStepIds`. |
| Dupliquer `storyFlags` | Fact stocke au plus une référence technique, pas l'état. |
| Tous les flags deviennent Facts auteur | Autoriser seulement debug, labels auteur sur sources claires. |
| Outcome devient Fact automatiquement | Mapping explicite seulement, après décision. |
| Battle outcome devient Fact automatiquement | Mapping explicite seulement, après décision. |
| World Rule fusionné avec Fact | P2-08 reste projection passive séparée. |
| Modifier `ProjectManifest` trop tôt | Aucune persistence sans consumer + migration. |
| Faire de `map_editor` la source de vérité | Projections editor restent dérivées. |

## 20. Ce que P2-07 décide

- Pas de code dans P2-07.
- Pas de `FactRegistry`.
- Pas de modèle persistant.
- Pas de modification `ProjectManifest`.
- Pas de modification `GameState` / `SaveData`.
- `GameState` et `SaveData` restent sources techniques.
- `completedStepIds` reste source de completion.
- `storyFlags` reste source technique des flags.
- Outcomes et battle outcomes ne deviennent pas automatiquement Facts.
- World Rule reste séparé.
- Trajectoire recommandée : future `FactPresentationReadModel` non persistante
  si P2-09/P2-10 le justifient.

## 21. Ce que P2-07 ne décide pas

- Structure finale d'un modèle `map_core`.
- JSON final.
- Migration `ProjectManifest`.
- UI picker.
- P2-08 World Rule adapter.
- P2-09 diagnostics implémentés.
- P2-10 picker read models implémentés.
- Reward Model.
- Money / XP / level-up.
- Selbrume réel.

## 22. Implémentation éventuelle

Aucune implémentation.

Justification :

- les consumers codés sont futurs ;
- les sources techniques existent déjà ;
- les diagnostics et pickers qui consommeraient la presentation layer sont P2-09
  et P2-10 ;
- un type Dart maintenant figerait trop tôt les `sourceKind`.

## 23. Tests / validations éventuels

Tests Dart/Flutter non exécutés et non requis : P2-07 est design-first et ne
modifie aucun code.

Validations attendues pour ce lot :

- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- contrôles hors scope sur `road_map_global.md`, `road_map_phase_1.md`,
  packages et host.

Tests futurs possibles :

- read model dérivé de flags/steps/outcomes ;
- labels manquants ;
- Fact source inconnue ;
- outcome non promu automatiquement ;
- battle outcome non promu automatiquement ;
- tri stable pour pickers ;
- mode debug qui expose les technical keys sans les promouvoir en UX principale.

## 24. Recommandation pour P2-08

P2-08 doit traiter :

```text
P2-08 — World Rule Predicate Adapter Contract
```

Recommandation :

- partir des `MapEntityRuntimePredicate` existants ;
- garder World Rule comme projection passive ;
- ne pas créer de WorldRuleRegistry prématuré ;
- réutiliser les labels conceptuels Fact si utiles ;
- ne jamais laisser World Rule écrire un Fact, compléter un Step ou déclencher
  une Scene.

## 25. Mise à jour de road_map_phase_2.md

Mise à jour attendue :

- `P2-07` passe à `✅ terminé` ;
- `P2-08` devient `🔜 prochain lot exact` ;
- résumé P2-07 ajouté ;
- fichiers créés / modifiés, commandes, décisions et changements de périmètre
  documentés.

## 26. Evidence Pack

### 26.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 26.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md
reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md
reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md
reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md
reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/application/story_flags_manager.dart
packages/map_runtime/lib/src/application/scenario_conditions.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
skills/README.md
AGENTS.md
```

### 26.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
```

### 26.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 26.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && grep -nE "P2-07|P2-08|Fact|fact|World Rule|world rule|GameState|SaveData|storyFlags|completedStepIds|completedCutsceneIds|scriptVariables|consumedEventIds|scenario\\.outcome|battle:|trainer_defeated|FactRegistry|Presentation|read model|ProjectManifest|Outcome|Battle" "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md || true; cd /Users/karim/Project/pokemonProject && grep -nE "storyFlags|activeFlags|completedStepIds|completedCutsceneIds|scriptVariables|consumedEventIds|scenario\\.outcome|battle:|trainer_defeated|setFlag|clearFlag|completeStep|emitOutcome|flagIsSet|flagIsUnset|stepCompleted|stepNotCompleted|chapterCompleted|chapterNotCompleted|cutsceneCompleted|cutsceneNotCompleted|flagReadNeverProduced|setFlagNeverRead|stepReadNeverCompleted|completeStepNeverRead|sourceOutcomeWithoutMatchingEmitOutcome|emitOutcomeWithoutMatchingSourceOutcome|MapEntityRuntimePredicate|NarrativeValidator" packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_gameplay/lib/src/script_condition_evaluator.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart packages/map_runtime/lib/src/application/story_flags_manager.dart packages/map_runtime/lib/src/application/scenario_conditions.dart packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart || true; cd /Users/karim/Project/pokemonProject && sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart && sed -n '1,320p' packages/map_core/lib/src/models/save_data.dart && sed -n '320,720p' packages/map_core/lib/src/models/save_data.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,320p' packages/map_core/lib/src/models/script_conditions.dart && sed -n '1,320p' packages/map_gameplay/lib/src/script_condition_evaluator.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,280p' packages/map_gameplay/lib/src/game_state_mutations.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,280p' packages/map_core/lib/src/models/scenario_asset.dart && sed -n '650,780p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart && sed -n '940,1040p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart; cd /Users/karim/Project/pokemonProject && grep -nE "flagReadNeverProduced|setFlagNeverRead|stepReadNeverCompleted|completeStepNeverRead|sourceOutcomeWithoutMatchingEmitOutcome|emitOutcomeWithoutMatchingSourceOutcome|storyFlags|completedStepIds|flag|step|outcome|diagnostic" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart || true && sed -n '1,220p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '220,520p' packages/map_core/lib/src/operations/narrative_validator.dart && sed -n '520,860p' packages/map_core/lib/src/operations/narrative_validator.dart; cd /Users/karim/Project/pokemonProject && sed -n '80,120p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart && sed -n '680,740p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart && sed -n '1,120p' packages/map_runtime/lib/src/application/scenario_runtime/scenario_battle_outcome_flags.dart && sed -n '160,240p' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart && sed -n '1,100p' packages/map_runtime/lib/src/application/story_flags_manager.dart && sed -n '1,120p' packages/map_runtime/lib/src/application/scenario_conditions.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,320p' packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart], queries=["GameState storyFlags completedStepIds completedCutsceneIds scriptVariables consumedEventIds bag party money truth source", "Scenario actions setFlag clearFlag completeStep emitOutcome giveItem givePokemon startTrainerBattle write truth", "ScriptCondition flagIsSet flagIsUnset stepCompleted stepNotCompleted chapterCompleted cutsceneCompleted variable party reads", "NarrativeValidator flagReadNeverProduced setFlagNeverRead stepReadNeverCompleted completeStepNeverRead outcome diagnostics", "scenario outcome flag scenario.outcome battle outcome battle: trainer_defeated fact relation", "World Rule MapEntityRuntimePredicate reads flags steps chapters cutscenes no write facts", "P2-07 Fact Presentation Layer no FactRegistry no ProjectManifest GameState source truth", "P2-08 World Rule separate Fact Presentation consumers P2-09 P2-10"])
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && grep -nE "MapEntityRuntimePredicate|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted|chapterCompleted|chapterNotCompleted|cutsceneCompleted|cutsceneNotCompleted|visibilityRule|dialogueVariants" packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart || true && sed -n '1,260p' packages/map_core/lib/src/models/map_entity_payloads.dart && sed -n '260,620p' packages/map_core/lib/src/models/map_entity_payloads.dart; cd /Users/karim/Project/pokemonProject && sed -n '1,90p' packages/map_core/lib/src/operations/narrative_validator.dart && grep -nE "flagReadNeverProduced|setFlagNeverRead|stepReadNeverCompleted|completeStepNeverRead|sourceOutcomeWithoutMatchingEmitOutcome|emitOutcomeWithoutMatchingSourceOutcome" packages/map_core/lib/src/operations/narrative_validator.dart], queries=["MapEntityRuntimePredicateKind storyFlagSet stepCompleted chapterCompleted cutsceneCompleted refId source truth", "NarrativeValidationDiagnosticKind flagReadNeverProduced setFlagNeverRead stepReadNeverCompleted completeStepNeverRead outcome mismatch"])
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && grep -nE "gameStateFromSaveData|saveDataFromGameState|normalizeLoadedGameState|storyFlags:|StoryFlags|activeFlags|progression" packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/game_state.dart || true && sed -n '360,620p' packages/map_core/lib/src/models/save_data.dart], queries=["gameStateFromSaveData saveDataFromGameState storyFlags activeFlags progression mapping duplication"])
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && grep -R -nE "gameStateFromSaveData|saveDataFromGameState|normalizeLoadedGameState|activeFlags|progression\\.storyFlags" packages/map_core/lib packages/map_runtime/lib packages/map_gameplay/lib || true], queries=["gameStateFromSaveData saveDataFromGameState normalizeLoadedGameState activeFlags progression.storyFlags"])
ctx_batch_execute(commands=[cd /Users/karim/Project/pokemonProject && sed -n '1,180p' packages/map_core/lib/src/operations/game_state_persistence.dart], queries=["gameStateFromSaveData saveDataFromGameState migratedFlags progression.storyFlags storyFlags.activeFlags"])
sed -n '1,840p' "MVP Selbrume/road_map_phase_2.md"
grep -n "À compléter" reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
grep -nE "^## [0-9]+\\." reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
sed -n '1,60p' "MVP Selbrume/road_map_phase_2.md"
sed -n '540,650p' "MVP Selbrume/road_map_phase_2.md"
sed -n '734,920p' reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
```

### 26.6 git diff --check

```text
```

### 26.6-bis git diff --no-index --check du rapport créé

```text
```

### 26.6-ter Contrôle hors scope global / phase 1 / battle / host

```text
```

### 26.6-quater Contrôle hors scope packages code

```text
```

### 26.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 65 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 58 insertions(+), 7 deletions(-)
```

### 26.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 26.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
```

### 26.10 Tests / analyze

```text
Non exécutés — P2-07 est design-first/documentaire et ne modifie aucun code.
```

## 27. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?

- Oui : rapport P2-07 et roadmap Phase 2 uniquement.

Le rapport P2-07 existe-t-il au bon chemin ?

- Oui : `reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?

- Oui : P2-07 terminé et P2-08 prochain lot exact.

`road_map_global.md` est-elle restée intacte ?

- Oui : contrôle hors scope final sans sortie.

Aucun code n'a-t-il été modifié, ou le code modifié est-il justifié ?

- Aucun code n'a été modifié.

Aucun build_runner n'a-t-il été lancé ?

- Oui.

P2-08 n'a-t-il pas été commencé ?

- Oui. P2-08 est uniquement recommandé comme prochain lot.

Fact reste-t-il une présentation lisible d'une vérité ?

- Oui. La vérité reste portée par `GameState`, `SaveData` et les sources
  techniques existantes.

Le contrat recommandé évite-t-il FactRegistry prématuré ?

- Oui. La trajectoire est une presentation layer non persistante.

Les sources techniques restent-elles sources of truth ?

- Oui.

Les consumers sont-ils explicites ?

- Oui : Validator, P2-08, P2-09, P2-10, Phase 4 authoring minimal.

La décision d'implémentation est-elle claire ?

- Oui : design-only, aucun code.

Le prochain lot exact est-il clair ?

- Oui : `P2-08 — World Rule Predicate Adapter Contract`.

### Regard critique sur le prompt

Le prompt autorise une implémentation minimale conditionnelle, mais les
conditions de sécurité sont plus fortes que le besoin immédiat : les consumers
codés sont encore futurs et P2-08/P2-09/P2-10 doivent préciser les usages.
La formulation "Fact Descriptor" peut pousser à créer un registre, alors que les
preuves pointent plutôt vers une presentation layer dérivée et non persistante.
