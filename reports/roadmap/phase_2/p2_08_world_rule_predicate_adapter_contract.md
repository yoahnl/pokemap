# P2-08 — World Rule Predicate Adapter Contract

## 1. Résumé exécutif

P2-08 reste design-first et ne produit aucun code. Le lot décide que World Rule
doit rester une presentation lisible des projections passives du monde, derivee
des predicates runtime et metadata existantes, sans nouvelle persistence.

La verite technique observee est deja portee par :

- `MapEntityRuntimePredicate` pour lire flags, steps, chapters et cutscenes ;
- `MapEntityNpcVisibilityRule` pour afficher ou masquer passivement un NPC ;
- `MapEntityConditionalDialogue` pour choisir passivement un dialogue selon une
  condition ;
- `StepStudioWorldPresenceIndex` pour filtrer certaines presences selon les
  `completedStepIds` ;
- `GlobalStoryChapterStepIndex` pour deriver `chapterCompleted` depuis les
  steps completes ;
- `GameState` / `SaveData` comme sources techniques de verite.

Decision recommandee :

- ne pas creer de modele persistant ;
- ne pas modifier `ProjectManifest` ;
- ne pas creer de `WorldRuleRegistry` ;
- ne pas dupliquer `MapEntityRuntimePredicate` ;
- ne pas dupliquer Step Studio world presence ;
- garder Fact Presentation separe de World Rule ;
- garder Event et Scene separes de World Rule ;
- recommander une future `WorldRuleReadModel` /
  `WorldRulePredicateAdapter` non persistante, derivee des predicates et
  metadata existants, si P2-09/P2-10 le justifient.

La decision d'implementation P2-08 est donc :

```text
B — Predicate adapter / read model recommandé plus tard : aucun code maintenant.
```

Le prochain lot exact est :

```text
P2-09 — Narrative Validator Diagnostic Expansion
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports demandes ;
- audit cible de `MapEntityRuntimePredicate` ;
- audit des visibility rules NPC ;
- audit des conditional dialogues ;
- audit de Step Studio world presence ;
- audit du runtime Global Story chapter ;
- comparaison des options World Rule existant / adapter / registry ;
- decision d'implementation P2-08 ;
- proposition de contrat conceptuel non implemente ;
- mise a jour de `MVP Selbrume/road_map_phase_2.md`.

Exclus :

- code applicatif ;
- modele `map_core` ;
- `WorldRuleRegistry` persistant ;
- modification `GameState` ;
- modification `SaveData` ;
- modification `ProjectManifest` ;
- JSON, migration, Freezed, JsonSerializable, build_runner ;
- UI ;
- diagnostic P2-09 implemente ;
- picker read models P2-10 implementes ;
- Selbrume final.

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` : phase globale et contraintes.
- `MVP Selbrume/road_map_phase_2.md` : statut P2-08 et prochain lot.
- `MVP Selbrume/road_map_phase_1.md` : cloture Phase 1.
- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
  : cadrage audit-first.
- `reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md` :
  inventaire technique initial.
- `reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md`
  : `completedStepIds` reste source de completion.
- `reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md` : Event
  reste declencheur.
- `reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md` :
  Scene reste orchestration derivee de `ScenarioAsset`.
- `reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md` : outcome ne
  devient pas Fact automatiquement.
- `reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md` :
  battle outcome reste separe de scenario outcome et Fact.
- `reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md` :
  Fact Presentation reste non persistante et separee de World Rule.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  : concepts figes.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` :
  proposition World Rule Predicate Adapter.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` :
  besoins auteur no-code.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` :
  grammaire Fact / World Rule.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` :
  modele produit canonique.

Code lu en lecture seule :

- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/scenario_asset.dart`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_core/lib/src/validation/validators.dart`
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart`
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart`
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart`
- `packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart`
- `packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart`

Instructions et contexte :

- `AGENTS.md`
- `skills/README.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md`
- `/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md`

## 4. Rappel Phase 1 / P2-01 à P2-07

Phase 1 a fige la grammaire :

```text
Fact nomme ce qui est vrai.
World Rule projette passivement.
Event déclenche.
Scene orchestre.
Validator diagnostique.
```

P2-01 a confirme que les projections conditionnelles existent deja dans les
payloads map entity, predicates runtime, metadata Step Studio et runtime Global
Story.

P2-02 a confirme que `completedStepIds` reste la source de completion et que
`chapterCompleted` peut etre derive via un index, sans etat chapter stocke.

P2-03 a garde Event comme declencheur et refuse la duplication des runtime
source events.

P2-04 a garde Scene comme orchestration derivee de `ScenarioAsset`, sans wrapper
persistant.

P2-05 a garde les outcomes comme resultats interpretes, pas comme Facts
automatiques.

P2-06 a garde les battle outcomes separes, sans coupler `map_battle` au
Narrative Studio.

P2-07 a decide que Fact Presentation nomme les verites techniques sans creer de
nouvelle source de verite. P2-08 doit donc brancher World Rule sur ces verites,
mais sans les ecrire.

## 5. Problème à résoudre

Le produit veut une phrase auteur du type :

```text
Quand le step "Parler à Lysa" est terminé, cacher Mael sur le port.
```

Le repo porte aujourd'hui une logique technique du type :

- predicate `stepCompleted` avec `refId` ;
- visibility rule `visibleWhen` ou `hiddenWhen` ;
- conditional dialogue avec predicate ;
- metadata Step Studio `worldChanges` ;
- chapter completion derivee.

Le probleme P2-08 est de relier ces niveaux sans :

- creer un `WorldRuleRegistry` ;
- dupliquer `MapEntityRuntimePredicate` ;
- transformer World Rule en Event ;
- laisser World Rule ecrire un Fact ;
- laisser World Rule completer un Step ;
- modifier `ProjectManifest`.

## 6. Inventaire MapEntityRuntimePredicate

`MapEntityRuntimePredicateKind` expose les kinds suivants :

| Kind | Verite lue | Source technique | Alignement World Rule | Risque |
|---|---|---|---|---|
| `storyFlagSet` | flag actif | `GameState.storyFlags.activeFlags` | "si un fait/flag est vrai" | exposer un flag brut comme UX principale |
| `storyFlagUnset` | flag absent | `GameState.storyFlags.activeFlags` | "si un fait/flag est faux" | negation difficile a labelliser |
| `stepCompleted` | step termine | `GameState.progression.completedStepIds` | "apres ce step" | dupliquer `completedStepIds` |
| `stepNotCompleted` | step non termine | `GameState.progression.completedStepIds` | "avant ce step" | logique inverse cachee |
| `chapterCompleted` | chapter derive comme complet | `GlobalStoryChapterStepIndex` | "apres ce chapter" | croire que Chapter est stocke |
| `chapterNotCompleted` | chapter derive comme incomplet | `GlobalStoryChapterStepIndex` | "tant que ce chapter n'est pas complet" | ambiguity si index absent |
| `cutsceneCompleted` | cutscene/scenario complete | `GameState.progression.completedCutsceneIds` | "apres cette cutscene/scene" | confusion Scene vs Cinematic |
| `cutsceneNotCompleted` | cutscene/scenario non complete | `GameState.progression.completedCutsceneIds` | "avant cette cutscene/scene" | negation implicite |

`MapEntityRuntimePredicate` est minimal :

- `kind` ;
- `refId`.

Observation :

- le predicate lit une verite ;
- il ne declenche rien ;
- il n'ecrit rien ;
- il ne porte aucun label auteur ;
- il peut etre presente comme World Rule plus tard via un adapter non
  persistant.

Ce qui manque pour un authoring no-code :

- labels humains ;
- target explicite de projection ;
- source metadata ;
- diagnostics sur references inconnues ;
- priorite/fallback lisibles ;
- explication de la verite lue via Fact Presentation.

## 7. Inventaire NPC visibility rules

`MapEntityNpcVisibilityRule` porte :

- `mode` : `always`, `visibleWhen`, `hiddenWhen` ;
- `predicate` optionnel.

Le runtime `MapEntityRuntimePredicateEvaluator.isNpcPresentOnMap` applique :

- non-NPC : present ;
- rule absente ou `always` : present ;
- predicate absent pour une rule conditionnelle : cache par securite ;
- `visibleWhen` : present si le predicate est vrai ;
- `hiddenWhen` : present si le predicate est faux.

Alignement World Rule :

```text
World Rule passive = lit une vérité et projette une présence NPC.
```

Diagnostics futurs possibles :

- visibility rule conditionnelle sans predicate ;
- predicate avec `refId` vide ;
- `stepId` inconnu ;
- `chapterId` inconnu dans l'index Global Story ;
- `cutsceneId` inconnu ;
- `storyFlag` jamais produit ;
- conflit entre visibility rule et Step Studio world presence ;
- rule `hiddenWhen` avec label auteur ambigu.

Garde-fou :

Une visibility rule n'est pas un Event. Elle ne doit pas lancer de Scene, emettre
d'outcome, completer de step ou ecrire de flag.

## 8. Inventaire conditional dialogues

`MapEntityConditionalDialogue` porte :

- `when` : `MapEntityRuntimePredicate` ;
- `dialogue` : reference de dialogue.

Le runtime `resolveNpcDialogue` parcourt les `conditionalDialogues` et retourne
le premier dialogue dont le predicate est satisfait. Sinon, il revient au
dialogue par defaut du NPC.

Alignement World Rule :

```text
World Rule passive = lit une vérité et projette le dialogue choisi.
```

Ce qui est deja supporte :

- projection conditionnelle du dialogue ;
- fallback vers dialogue par defaut ;
- ordre implicite par ordre de liste.

Risques :

- l'ordre devient une priorite cachee ;
- deux dialogues conditionnels peuvent etre vrais en meme temps ;
- la reference dialogue peut etre inconnue ;
- un auteur peut vouloir faire de ce dialogue une Scene, ce qui sortirait du
  role World Rule.

Diagnostics futurs possibles :

- conditional dialogue qui reference un dialogue inconnu ;
- conditional dialogue sans fallback NPC ;
- plusieurs conditions vraies possibles sans priorite explicite ;
- predicate lisant une verite inconnue ;
- predicate duplique entre plusieurs dialogues.

## 9. Inventaire Step Studio world presence

`step_studio_world_presence_runtime.dart` evalue les `worldChanges` issus des
metadata Step Studio selon `GameState.progression.completedStepIds`.

Les kinds observes :

- `visibleBeforeStepCompletion` ;
- `visibleAfterStepCompletion` ;
- `hiddenAfterStepCompletion` ;
- `visibleOnlyWhenCompleted`.

Chaque regle porte notamment :

- `mapId` ;
- `entityId` ;
- `sourceStepId` ;
- `presenceRule`.

Observation importante :

- ce systeme est passif ;
- il lit la completion de step ;
- il filtre la presence d'entites, surtout NPC dans l'usage runtime lu ;
- il ne complete pas de step ;
- il n'ecrit pas de Fact ;
- il ne declenche pas de Scene.

Chevauchement avec `MapEntityRuntimePredicate` :

- les deux peuvent projeter une presence selon un step ;
- les deux peuvent affecter un NPC ;
- les deux doivent etre combines en amont si les deux systemes sont actifs ;
- un adapter World Rule futur doit les exposer comme sources techniques
  differentes, pas les fusionner en registry.

Risques :

- conflit visible/cache entre Step Studio world presence et `visibilityRule` ;
- metadata authoring qui devient source cachee sans diagnostic ;
- target non supporte runtime qui donne une fausse impression d'effet ;
- duplication d'une meme intention dans deux systemes.

## 10. Inventaire Global Story chapter runtime

`GlobalStoryChapterStepIndex` derive la completion de chapter depuis :

- metadata Global Story / scenario metadata ;
- mapping chapter -> step ids ;
- `GameState.progression.completedStepIds`.

Observation :

- Chapter n'est pas un etat stocke ;
- `chapterCompleted` est derive ;
- si l'index est absent ou incomplet, la lecture `chapterCompleted` est fragile ;
- la World Rule peut lire cette derivation, mais ne doit pas creer une nouvelle
  verite chapter.

Alignement World Rule :

```text
Quand tous les steps du chapter sont terminés, projeter un changement passif.
```

Garde-fou :

Un futur adapter doit exposer `chapterCompleted` comme verite derivee, avec sa
source metadata, et non comme flag persistant.

## 11. Relation World Rule / Fact Presentation

Fact Presentation peut fournir a World Rule :

- un label humain pour un flag technique ;
- un label pour un step complete ;
- un label pour une cutscene/scenario complete ;
- un label pour un battle outcome ou trainer defeated ;
- un lien source/consumer ;
- un label debug technique.

World Rule peut lire une verite presentee, mais ne doit jamais :

- creer un Fact ;
- modifier `GameState` ;
- completer un Step ;
- emettre un Outcome ;
- convertir un outcome en Fact ;
- convertir une projection en source de verite.

Formulation recommandee :

```text
Fact nomme la vérité.
World Rule lit cette vérité.
World Rule projette une conséquence passive.
```

## 12. Relation World Rule / Event / Scene

Frontiere :

| Concept | Role | Peut lire une verite ? | Peut ecrire / declencher ? |
|---|---|---:|---:|
| Fact | nomme une verite | oui | non |
| World Rule | projette passivement | oui | non |
| Event | declenche | oui, via condition | oui, declenche une Scene/scenario |
| Scene | orchestre | oui | oui, via actions/effects |

World Rule ne doit pas :

- devenir un Event conditionnel ;
- lancer une Scene ;
- completer un Step ;
- emettre un Outcome ;
- ecrire un Fact ;
- devenir un script cache.

La distinction est importante pour garder l'auteur no-code lisible :

```text
World Rule = apparaitre, disparaitre, choisir un dialogue, rendre disponible.
Event = quand le joueur agit ou entre dans une zone, declencher.
Scene = sequence d'actions orchestrees.
```

## 13. Inventaire Validator existant

Diagnostics/validations liees ou proches :

- `conditionalDialogueReferencesUnknownDialogue` ;
- `flagReadNeverProduced` ;
- `setFlagNeverRead` ;
- `stepReadNeverCompleted` ;
- `completeStepNeverRead`.

Observations :

- le validator collecte deja des lectures de flags et steps via predicates ;
- les conditional dialogues inconnus sont deja une surface diagnostique ;
- les reads chapter/cutscene dans `MapEntityRuntimePredicate` semblent moins
  couverts par les diagnostics transverses que flags/steps ;
- les conflits entre Step Studio world presence et visibility rules ne sont pas
  traites dans P2-08 ;
- P2-09 est le bon lot pour etendre les diagnostics.

Diagnostics possibles sans persistence :

- predicate `refId` vide ;
- predicate chapter/cutscene sans source resolue ;
- step lu par World Rule jamais complete par Scene ;
- flag lu par World Rule jamais produit ;
- conditional dialogue vers dialogue inconnu ;
- visibility rule conditionnelle sans predicate ;
- Step Studio world presence target inconnue ;
- Step Studio world presence step inconnu ;
- conflit de projection entre Step Studio et map entity visibility ;
- rule passive qui tente de representer une action active.

## 14. Consumers explicites

| Consumer | Besoin | Besoin immediat ? | Necessite persistence ? |
|---|---|---:|---:|
| `NarrativeValidator` | diagnostiquer references et conflits | oui, P2-09 | non |
| `ProjectValidator` | surface projet globale si necessaire | futur | non |
| P2-10 Reference Picker Read Models | listes de rules/targets/facts lisibles | oui, apres P2-09 | non |
| Future Fact Presentation | labels des verites lues | futur | non |
| Future map editor authoring | expliquer les projections no-code | Phase 4 | non au depart |
| Runtime map entity evaluator | execution passive existante | deja servi | non |
| Step Studio world presence runtime | execution passive existante | deja servi | non |

Conclusion :

Les consumers justifient une trajectoire adapter/read model non persistante,
mais pas une implementation P2-08. P2-09 doit d'abord choisir les diagnostics et
P2-10 les read models de picker.

## 15. Options de contrat

### Option A — Garder l'existant + diagnostics futurs

Description :

Utiliser uniquement `MapEntityRuntimePredicate`, `visibilityRule`,
`conditionalDialogues` et Step Studio world presence existants.

Avantages :

- aucun code ;
- aucune migration ;
- aucune duplication ;
- runtime actuel respecte deja la passivite ;
- P2-09 peut ajouter des diagnostics cibles.

Risques :

- vocabulaire auteur encore technique ;
- metadata Step Studio et predicates map entity restent deux surfaces separees ;
- conflits non visibles sans diagnostics.

Consumers servis :

- runtime actuel ;
- diagnostics futurs.

Limites :

- pickers et labels humains devront attendre P2-10.

Verdict :

Acceptable comme etat immediat, mais insuffisant comme trajectoire auteur.

### Option B — World Rule Predicate Adapter / read model non persistant

Description :

Creer plus tard une vue produit derivee des predicates et metadata existants.

Avantages :

- clarifie sans dupliquer ;
- garde les sources techniques actuelles ;
- sert P2-09 et P2-10 ;
- peut normaliser labels, targets, projection kinds et diagnostics ;
- respecte "adapter avant de persister".

Risques :

- l'adapter peut devenir un modele persistant deguise ;
- la fusion des sources peut masquer les differences runtime ;
- il faut eviter les IDs globaux artificiels.

Diagnostics possibles :

- targets inconnus ;
- predicates invalides ;
- conflits de projection ;
- references Fact/Step/Chapter/Cutscene inconnues.

Compatibilite :

- forte compatibilite P2-09/P2-10 ;
- pas de migration.

Verdict :

Trajectoire recommandee, mais implementation reportee.

### Option C — Contrat pur minimal dans map_core

Description :

Creer maintenant ou plus tard un type pur `WorldRuleReadModel`.

Champs minimaux possibles :

- `worldRuleId` ;
- `humanLabel` ;
- `sourceKind` ;
- `sourceId` ;
- `targetKind` ;
- `targetId` ;
- `projectionKind` ;
- `conditionKind` ;
- `conditionTechnicalKey` ;
- `diagnostics`.

Avantages :

- testable ;
- partageable entre validator et pickers ;
- peut rester Flutter/Flame-free.

Risques :

- consumer pas encore assez ferme avant P2-09/P2-10 ;
- risque de dupliquer les predicates existants ;
- risque d'ancrer trop tot les shapes d'auteur.

Pourquoi pas maintenant :

- P2-08 doit decider, pas implementer ;
- P2-09 doit preciser les diagnostics ;
- P2-10 doit preciser les pickers.

Verdict :

Possible plus tard, pas maintenant.

### Option D — WorldRuleRegistry persistant

Description :

Creer un registre persistant de World Rules.

Risques :

- migration `ProjectManifest` prematuree ;
- duplication de `MapEntityRuntimePredicate` ;
- duplication Step Studio world presence ;
- nouvelle source de verite ;
- conflits avec metadata editor ;
- authoring trop rigide trop tot.

Verdict :

Refuser maintenant.

### Option E — Fusionner Fact et World Rule

Description :

Traiter les Facts comme World Rules ou les World Rules comme Facts.

Risques :

- Fact nomme une verite, World Rule projette une consequence ;
- fusionner brouille lecture et projection ;
- World Rule pourrait devenir une pseudo-verite ;
- Fact Presentation P2-07 perdrait son role.

Verdict :

Refuser.

### Option F — World Rule active / Event-like

Description :

Autoriser World Rule a declencher Scene, ecrire Fact, completer Step ou emettre
Outcome.

Risques :

- World Rule devient Event cache ;
- erreurs runtime difficiles a diagnostiquer ;
- completion de step invisible dans l'auteur ;
- duplication de Scene orchestration ;
- violations directes de la grammaire Phase 1.

Verdict :

Refuser strictement.

## 16. Matrice comparative

| Option | Complexite | Migration | Risque duplication | Support Validator | Support pickers | Respect passivite | Recommandation |
|---|---|---:|---:|---:|---:|---:|---|
| A — Existant + diagnostics futurs | faible | non | faible | moyen | faible | fort | garder immediatement |
| B — Adapter/read model futur | moyenne | non | faible si derive | fort | fort | fort | trajectoire principale |
| C — Contrat pur maintenant/plus tard | moyenne | non | moyen | fort | fort | fort | plus tard seulement |
| D — Registry persistant | forte | oui | fort | moyen | moyen | moyen | refuser |
| E — Fusion Fact/World Rule | moyenne | possible | fort | faible | faible | faible | refuser |
| F — World Rule active | forte | possible | fort | faible | faible | nul | refuser strictement |

## 17. Décision d’implémentation P2-08

Un `WorldRulePredicateAdapter` / `WorldRuleReadModel` est-il necessaire
maintenant ?

```text
Non.
```

Quels consumers explicites le justifient ?

- P2-09 diagnostics ;
- P2-10 picker read models ;
- future authoring UI Phase 4.

Ces consumers justifient une trajectoire, mais pas une implementation dans
P2-08.

Peut-il etre derive de `MapEntityRuntimePredicate` / Step Studio metadata sans
persistence ?

```text
Oui.
```

Peut-il attendre P2-09 / P2-10 ?

```text
Oui. P2-09 doit d'abord stabiliser les diagnostics prioritaires.
```

Comment eviter de dupliquer `MapEntityRuntimePredicate` ?

- garder les predicates runtime comme source technique ;
- produire plus tard des vues derivees ;
- conserver `sourceKind` / `sourceId` pour tracer l'origine ;
- ne pas recreer les enums runtime sous un autre nom persistant.

Comment eviter de creer un `WorldRuleRegistry` ?

- ne pas ajouter de stockage ;
- ne pas modifier `ProjectManifest` ;
- ne pas creer de liste persistante de rules ;
- deriver depuis map entity payloads et metadata authoring existants.

Quels diagnostics deviennent possibles ?

- references inconnues ;
- predicates incomplets ;
- conflits de projections ;
- rules actives interdites ;
- targets non supportes runtime.

La persistence est-elle necessaire ?

```text
Non.
```

Verdict P2-08 :

```text
B — Predicate adapter / read model recommandé plus tard : aucun code maintenant.
```

## 18. Contrat conceptuel recommandé

Contrat conceptuel non implemente :

```text
WorldRuleReadModel
```

ou :

```text
WorldRulePredicateAdapter
```

Champs conceptuels possibles :

- `worldRuleId` ;
- `humanLabel` ;
- `description` ;
- `sourceKind` ;
- `sourceId` ;
- `targetKind` ;
- `targetId` ;
- `projectionKind` ;
- `conditionKind` ;
- `conditionTechnicalKey` ;
- `conditionHumanLabel` ;
- `factPresentationId` ;
- `mapId` ;
- `entityId` ;
- `dialogueId` ;
- `stepId` ;
- `chapterId` ;
- `cutsceneId` ;
- `isPassive` ;
- `isRuntimeSupported` ;
- `priority` ;
- `fallbackBehavior` ;
- `diagnostics`.

`sourceKind` conceptuels possibles :

- `mapEntityVisibilityRule` ;
- `mapEntityConditionalDialogue` ;
- `stepStudioWorldPresence` ;
- `globalStoryChapterRuntime` ;
- `derivedPredicate`.

`targetKind` conceptuels possibles :

- `npcPresence` ;
- `npcDialogue` ;
- `mapEntityVisibility` ;
- `worldObjectPresence` ;
- `interactionAvailability` ;
- `authoringOnly`.

`projectionKind` conceptuels possibles :

- `show` ;
- `hide` ;
- `chooseDialogue` ;
- `makeAvailable` ;
- `makeUnavailable` ;
- `noRuntimeEffect`.

Contraintes :

- ce contrat n'est pas cree par P2-08 ;
- il ne doit pas dupliquer `MapEntityRuntimePredicate` ;
- il ne doit pas creer `WorldRuleRegistry` ;
- il doit etre derive autant que possible ;
- il ne doit pas fusionner Fact et World Rule ;
- il ne doit jamais declencher Scene ou ecrire Fact.

## 19. Diagnostics possibles

Diagnostics candidats pour P2-09 :

- predicate World Rule avec `refId` vide ;
- visibility rule conditionnelle sans predicate ;
- visibility rule target NPC absent ;
- conditional dialogue reference dialogue inconnu ;
- conditional dialogue sans fallback ;
- plusieurs conditional dialogues vrais sans priorite explicite ;
- `storyFlag` lu mais jamais produit ;
- step lu mais jamais complete ;
- chapter lu mais non resolu dans `GlobalStoryChapterStepIndex` ;
- cutscene lue mais inconnue ;
- Step Studio world presence target map/entity inconnu ;
- Step Studio world presence source step inconnu ;
- conflit entre Step Studio world presence et `visibilityRule` ;
- projection authoring non supportee runtime ;
- World Rule qui tente d'ecrire un flag ;
- World Rule qui tente de completer un step ;
- World Rule qui tente de declencher Scene/Event.

Ces diagnostics ne necessitent pas de persistence nouvelle. Ils peuvent etre
derives des payloads, metadata et validators existants.

## 20. Impacts sur P2-09 à P2-10

P2-09 — Narrative Validator Diagnostic Expansion :

- doit prioriser les diagnostics World Rule derivables sans nouveau modele ;
- doit couvrir predicates incomplets, references inconnues et conflits ;
- doit garder World Rule passive ;
- doit eviter de creer un registry par facilite.

P2-10 — Reference Picker Read Models :

- pourra reutiliser le futur shape conceptuel `WorldRuleReadModel` ;
- devra produire des labels humains pour predicates et targets ;
- devra distinguer source technique, target de projection et verite lue ;
- devra eviter tout widget Flutter dans le read model.

Phase 4 authoring :

- pourra exposer des workflows no-code de type "show/hide/choose dialogue" ;
- devra garder les rules passives et diagnostics-first.

## 21. Risques et garde-fous

| Risque | Garde-fou |
|---|---|
| Creer un `WorldRuleRegistry` premature | Deriver depuis payloads et metadata existants |
| Dupliquer `MapEntityRuntimePredicate` | Garder `sourceKind` / `sourceId`, pas de nouveau stockage |
| Dupliquer Step Studio world presence | L'exposer comme source technique distincte |
| Fusionner Fact et World Rule | Fact nomme, World Rule projette |
| Transformer World Rule en Event | Interdire trigger Scene/Event/action |
| World Rule ecrit un Fact | Interdire toute ecriture GameState |
| World Rule complete un Step | Completion reservee aux actions Scene/runtime |
| Metadata editor source cachee | Diagnostics sur sources et runtime support |
| Conflit visibility / world presence | Diagnostic P2-09 |
| UI auteur expose refIds bruts | Labels via Fact Presentation / picker read models |

## 22. Ce que P2-08 décide

- Aucun code n'est cree.
- Aucun modele persistant n'est cree.
- Aucun `WorldRuleRegistry` n'est cree.
- `ProjectManifest` n'est pas modifie.
- `GameState` / `SaveData` ne sont pas modifies.
- `MapEntityRuntimePredicate`, `visibilityRule`, `conditionalDialogues` et Step
  Studio world presence restent les sources techniques actuelles.
- World Rule reste passive.
- World Rule peut lire une verite, mais ne doit jamais l'ecrire.
- Fact Presentation reste separee.
- Event / Scene restent separes.
- La trajectoire recommandee est un adapter/read model non persistant futur si
  P2-09/P2-10 le justifient.

## 23. Ce que P2-08 ne décide pas

- Structure finale d'un modele `map_core`.
- JSON final.
- Migration `ProjectManifest`.
- UI authoring World Rule.
- Picker final.
- Diagnostics P2-09 implementes.
- Read models P2-10 implementes.
- Semantique finale des targets authoring-only.
- Selbrume reel.

## 24. Implémentation éventuelle

Aucune implementation n'est faite dans P2-08.

Raison :

- les consumers sont identifies, mais leur forme exacte depend de P2-09 et
  P2-10 ;
- une implementation maintenant risquerait de figer un read model avant les
  diagnostics ;
- aucune persistence n'est necessaire ;
- aucun code package ne doit changer pour trancher la decision.

## 25. Tests / validations éventuels

Tests Dart/Flutter non executes :

```text
Non exécutés — P2-08 est décision documentaire et ne modifie aucun code.
```

Validations documentaires effectuees :

- `git diff --no-index --check` sur le rapport cree ;
- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- controles hors scope sur roadmaps globales, packages et exemples.

## 26. Recommandation pour P2-09

Le prochain lot exact est :

```text
P2-09 — Narrative Validator Diagnostic Expansion
```

Recommandations :

- commencer par les diagnostics derivables sans nouveau stockage ;
- ajouter ou confirmer les diagnostics World Rule sur predicates, targets,
  dialogues, steps, chapters et conflicts ;
- traiter les conflits Step Studio world presence / visibility rule ;
- ne pas creer de `WorldRuleRegistry` ;
- ne pas convertir World Rule en Event ;
- ne pas creer de Fact automatiquement ;
- garder chaque diagnostic actionnable pour l'auteur.

## 27. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` est mise a jour pour indiquer :

- `P2-08 : ✅ terminé` ;
- `P2-09 : 🔜 prochain lot exact`.

Resume ajoute :

```text
P2-08 reste design-only, refuse WorldRuleRegistry et recommande un futur
WorldRuleReadModel / PredicateAdapter non persistant, derive des predicates et
metadata existants.
```

Fichiers crees :

- `reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md`

Fichiers modifies :

- `MVP Selbrume/road_map_phase_2.md`

Changements de perimetre :

- aucun.

Decisions utilisateur nouvelles :

- aucune decision imposee ; la recommandation est de poursuivre avec P2-09.

## 28. Evidence Pack

### 28.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 28.2 Fichiers lus

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
reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
AGENTS.md
skills/README.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
```

### 28.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
```

### 28.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 28.5 Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,220p' AGENTS.md
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/6188456f/skills/verification-before-completion/SKILL.md
grep -nE "P2-08|P2-09|World Rule|world rule|WorldRule|predicate|Predicate|MapEntityRuntimePredicate|visibilityRule|conditionalDialogues|Step Studio|worldChanges|GlobalStoryChapterStepIndex|chapterCompleted|Fact|Event|Scene|ProjectManifest|registry|Registry" "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_2.md" "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md reports/roadmap/phase_2/p2_02_story_step_descriptor_storyline_metadata_decision.md reports/roadmap/phase_2/p2_03_event_authoring_source_contract.md reports/roadmap/phase_2/p2_04_scene_scenario_asset_adapter_contract.md reports/roadmap/phase_2/p2_05_outcome_reference_contracts.md reports/roadmap/phase_2/p2_06_battle_reference_outcome_contract.md reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md || true
grep -nE "MapEntityRuntimePredicate|MapEntityRuntimePredicateKind|storyFlagSet|storyFlagUnset|stepCompleted|stepNotCompleted|chapterCompleted|chapterNotCompleted|cutsceneCompleted|cutsceneNotCompleted|MapEntityNpcVisibilityRule|MapEntityConditionalDialogue|visibilityRule|conditionalDialogues|resolveNpcDialogue|isNpcPresentOnMap|StepStudioWorldPresence|visibleBeforeStepCompletion|visibleAfterStepCompletion|hiddenAfterStepCompletion|visibleOnlyWhenCompleted|GlobalStoryChapterStepIndex|worldChanges|conditionalDialogueReferencesUnknownDialogue|flagReadNeverProduced|stepReadNeverCompleted|completeStepNeverRead" packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart || true
sed -n '1,220p' packages/map_core/lib/src/models/map_entity_payloads.dart && sed -n '220,520p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,320p' packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
sed -n '1,360p' packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
grep -nE "worldChanges|visibleBeforeStepCompletion|visibleAfterStepCompletion|hiddenAfterStepCompletion|visibleOnlyWhenCompleted|StepStudioWorldPresence|target|mapId|entityId|stepId|metadata" packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart || true
sed -n '1,360p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
sed -n '360,760p' packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart
grep -nE "chapter|Chapter|globalStory|step|Step|metadata|worldChanges|completed" packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart || true
sed -n '1,380p' packages/map_editor/lib/src/features/narrative/application/global_story_studio_authoring.dart
grep -nE "world|World|predicate|Predicate|visibility|conditional|chapter|step|outcome|MapEntityRuntimePredicate|worldChanges" packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart || true
sed -n '1,420p' packages/map_editor/lib/src/features/narrative/application/narrative_workspace_projection.dart
grep -nE "conditionalDialogueReferencesUnknownDialogue|flagReadNeverProduced|setFlagNeverRead|stepReadNeverCompleted|completeStepNeverRead|MapEntityRuntimePredicate|storyFlagSet|stepCompleted|chapterCompleted|cutsceneCompleted|readFlags|readSteps|conditional dialogue|visibility" packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart || true
sed -n '1,260p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '260,620p' packages/map_core/lib/src/operations/narrative_validator.dart
sed -n '620,860p' packages/map_core/lib/src/operations/narrative_validator.dart
grep -nE "sourceMapEnter|sourceTriggerEnter|sourceEntityInteract|sourceOutcome|setFlag|completeStep|emitOutcome|ScenarioRuntimeSourceEvent|dispatch|World Rule|MapEntityRuntimePredicate" packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_models.dart || true
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
sed -n '260,620p' "MVP Selbrume/road_map_phase_2.md"
ls -la reports/roadmap/phase_2
sed -n '620,1040p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1040,1420p' "MVP Selbrume/road_map_phase_2.md"
sed -n '1,220p' reports/roadmap/phase_2/p2_07_fact_descriptor_presentation_layer.md
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md || true
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
grep -nE "^## [0-9]+\." reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
grep -nE "Lot courant|Prochain lot exact|P2-08 :|P2-09 :|P2-09 — Narrative Validator Diagnostic Expansion" "MVP Selbrume/road_map_phase_2.md"
grep -nE "Décision d’implémentation P2-08|B — Predicate adapter|P2-09 — Narrative Validator" reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
```

### 28.6 git diff --check

```text

```

### 28.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 71 ++++++++++++++++++++++++++++++++++++----
 1 file changed, 64 insertions(+), 7 deletions(-)
```

### 28.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 28.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md
```

### 28.10 Tests / analyze

```text
Non exécutés — P2-08 est décision documentaire et ne modifie aucun code.
```

### 28.11 git diff --no-index --check du rapport créé

Commande :

```bash
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md || true
```

Sortie :

```text

```

### 28.12 Contrôle hors scope global / packages sensibles

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages/map_battle examples/playable_runtime_host
```

Sortie :

```text

```

### 28.13 Contrôle hors scope packages

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor examples/playable_runtime_host
```

Sortie :

```text

```

## 29. Auto-review critique

Le lot a-t-il modifie uniquement ce qui etait autorise ?

```text
Oui. Le lot cree un rapport et met a jour uniquement la roadmap Phase 2.
```

Le rapport P2-08 existe-t-il au bon chemin ?

```text
Oui : reports/roadmap/phase_2/p2_08_world_rule_predicate_adapter_contract.md.
```

`road_map_phase_2.md` a-t-elle ete mise a jour ?

```text
Oui.
```

`road_map_global.md` est-elle restee intacte ?

```text
Oui. Le controle hors scope final est vide.
```

Aucun code n'a-t-il ete modifie, ou le code modifie est-il justifie ?

```text
Aucun code n'a ete modifie.
```

Aucun build_runner n'a-t-il ete lance ?

```text
Oui. Aucun build_runner n'a ete lance.
```

P2-09 n'a-t-il pas ete commence ?

```text
Oui. P2-09 est seulement recommande comme prochain lot exact.
```

World Rule reste-t-elle passive ?

```text
Oui. Le rapport interdit explicitement trigger Scene/Event, ecriture Fact,
completion Step et emission Outcome depuis World Rule.
```

Le contrat recommande evite-t-il `WorldRuleRegistry` premature ?

```text
Oui. Le rapport refuse un registry persistant et recommande une vue derivee non
persistante seulement si P2-09/P2-10 le justifient.
```

Les predicates existants restent-ils sources techniques ?

```text
Oui. `MapEntityRuntimePredicate`, visibility rules, conditional dialogues et
Step Studio world presence restent les sources techniques.
```

Fact et World Rule restent-ils separes ?

```text
Oui. Fact nomme, World Rule projette.
```

Event / Scene restent-ils separes ?

```text
Oui. Event declenche, Scene orchestre, World Rule projette passivement.
```

Les consumers sont-ils explicites ?

```text
Oui : NarrativeValidator/P2-09, picker read models/P2-10, future authoring UI et
runtime evaluators existants.
```

La decision d'implementation est-elle claire ?

```text
Oui : B — adapter/read model recommande plus tard, aucun code maintenant.
```

Le prochain lot exact est-il clair ?

```text
Oui : P2-09 — Narrative Validator Diagnostic Expansion.
```

Regard critique sur le prompt :

```text
Le prompt est strict et utile : il force la separation entre projection passive,
Fact, Event et Scene. La principale vigilance est la taille de l'Evidence Pack :
les commandes exactes deviennent longues, mais c'est coherent avec la demande de
preuve verifiable.
```
