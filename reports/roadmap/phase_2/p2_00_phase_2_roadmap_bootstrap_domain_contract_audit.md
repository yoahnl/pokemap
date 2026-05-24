# P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

## 1. Résumé exécutif

P2-00 a validé le découpage Phase 2 avec une réserve mineure : le wording initial de la roadmap pouvait laisser croire que P2-00 devait faire un inventaire technique détaillé. Le lot confirme désormais une frontière stricte :

```text
P2-00 cadre l’audit.
P2-01 fait l’inventaire détaillé.
```

La roadmap Phase 2 reste cohérente et bornée. Les lots P2-00 à P2-CHECKPOINT-01 sont gardés, avec une vigilance particulière sur P2-02, P2-07 et P2-08 pour éviter de créer trop tôt un Step registry, un FactRegistry ou un WorldRuleRegistry.

Le prochain lot exact est :

```text
P2-01 — Existing Narrative Domain Inventory
```

## 2. Scope du lot

Inclus :

- lecture des roadmaps et rapports demandés ;
- validation de la roadmap Phase 2 ;
- audit de cadrage de l’existant ;
- clarification de la frontière P2-00 / P2-01 ;
- identification bornée des zones à inventorier en P2-01 ;
- mise à jour de `MVP Selbrume/road_map_phase_2.md` ;
- création du présent rapport P2-00.

Exclus :

- code applicatif ;
- tests Dart / Flutter ;
- nouveaux modèles ;
- nouveaux contrats implémentés ;
- schémas JSON ;
- migrations ;
- `build_runner` ;
- modification de `ProjectManifest` ;
- inventaire détaillé P2-01 ;
- contenu final Selbrume.

Fichiers créés :

- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_2.md`

Fichiers explicitement non modifiés :

- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_1.md`
- `packages/map_core`
- `packages/map_gameplay`
- `packages/map_battle`
- `packages/map_runtime`
- `packages/map_editor`
- `examples/playable_runtime_host`

## 3. Sources lues

Roadmaps et rapports :

- `MVP Selbrume/road_map_global.md` — contexte global ; confirme Phase 2 comme phase courante.
- `MVP Selbrume/road_map_phase_2.md` — roadmap vivante à valider et mettre à jour.
- `MVP Selbrume/road_map_phase_1.md` — statut Phase 1 clôturée et historique.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md` — verdict de clôture Phase 1 et passage Phase 2.
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md` — proposition initiale des lots Phase 2.
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md` — besoins pickers, validations et diagnostics.
- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md` — mapping conceptuel Golden Slice.
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md` — structure Storyline / Chapter / Story Step.
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md` — frontières Fact / World Rule.
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md` — frontières Event / Scene / Cinematic.
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md` — modèle produit canonique Phase 1.
- `MVP Selbrume/road_map.md` — historique NS-GS.
- `MVP Selbrume/narrative_studio.md` — contexte produit Narrative Studio.
- `MVP Selbrume/selbrume.md` — scénario de référence conceptuel.
- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md` — stratégie produit phasée.

Rapports NS-GS :

- `reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md` — bilan des preuves gameplay et limites Level 2 / Level 3 / Level 4.
- `reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md` — correction de labels de preuve.
- `reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md` — Validator V0 existant et limites.
- `reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md` — readiness side quest / optional storyline.
- `reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md` — limites rewards money / XP.

Zones code inspectées en lecture seule :

- `packages/map_core/lib/src/models/scenario_asset.dart` — zone critique Scene / ScenarioAsset.
- `packages/map_core/lib/src/models/project_manifest.dart` — agrégat projet et risque migration.
- `packages/map_core/lib/src/models/game_state.dart` — stockage GameState / flags.
- `packages/map_core/lib/src/models/save_data.dart` — save state, `completedStepIds`, `storyFlags`.
- `packages/map_core/lib/src/models/script_conditions.dart` — conditions existantes.
- `packages/map_core/lib/src/models/map_entity_payloads.dart` — predicates runtime de présence / projection.
- `packages/map_core/lib/src/operations/narrative_validator.dart` — diagnostics narratifs existants.
- `packages/map_core/lib/src/validation/validators.dart` — validation projet/scénarios.
- `packages/map_gameplay/lib/src/game_state_mutations.dart` — mutations GameState / step completion.
- `packages/map_gameplay/lib/src/script_condition_evaluator.dart` — lecture conditions.
- `packages/map_runtime/lib/src/application/scenario_runtime/` — source events, executor, effects, battle outcome flags.
- `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart` — évaluation passive des predicates.
- `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart` — runtime metadata Global Story / steps.
- `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart` — présence monde dérivée de metadata Step Studio.
- `packages/map_editor/lib/src/features/narrative/` — projections et authoring Narrative Studio.
- `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` — use cases scénario editor.

## 4. Rappel Phase 1 / Checkpoint

La Phase 1 est clôturée avec réserves mineures. Elle a figé la grammaire produit :

```text
Storyline organise.
Chapter sectionne.
Story Step jalonne.
Event déclenche.
Scene orchestre.
Cinematic met en scène.
Yarn produit des outcomes.
Battle résout.
Scene interprète.
Fact nomme ce qui est vrai.
World Rule projette passivement.
Validator diagnostique.
```

Les réserves restent structurantes pour Phase 2 :

- pas encore de runtime Flame Golden Slice prouvé ;
- pas encore de projet disque Selbrume ;
- pas encore de contrats `map_core` dédiés à la grammaire Phase 1 ;
- pas encore d’UI authoring no-code finale ;
- pas encore de Selbrume réel.

## 5. Objectif réel de P2-00

P2-00 n’est pas l’inventaire exhaustif. Son objectif réel est de vérifier que la Phase 2 est correctement bornée avant de laisser P2-01 explorer les structures existantes en détail.

P2-00 répond à ces questions :

- La roadmap Phase 2 est-elle cohérente ?
- Les lots sont-ils dans un ordre sain ?
- Les lots se chevauchent-ils ?
- Quelles zones doivent être inventoriées précisément en P2-01 ?
- Quels contrats ne doivent surtout pas être codés trop tôt ?

Conclusion :

```text
P2-00 prépare la carte.
P2-01 explore le territoire.
```

## 6. Frontière P2-00 / P2-01

| Sujet | P2-00 | P2-01 |
|---|---|---|
| `ScenarioAsset` | Confirme que c’est la zone critique pour Scene / ScenarioAsset. | Inventorie champs, metadata, outcomes, nodes, edges, scopes, usages runtime/editor/tests. |
| Metadata editor | Identifie Global Story, Step Studio et Cutscene Studio comme sources probables. | Cartographie formats, clés metadata, persistence, usages et diagnostics. |
| Validator | Confirme que Validator est un axe central Phase 2. | Inventorie diagnostics existants, gaps et points d’extension. |
| Runtime source events | Confirme la présence d’événements runtime à ne pas dupliquer aveuglément. | Détaille `mapEnter`, `triggerEnter`, `entityInteract`, `outcomeReceived` et leurs consumers. |
| Predicates / World Rules | Identifie les predicates runtime comme base probable d’adapter World Rule. | Détaille kinds, targets, usages, limites et conflits potentiels. |
| Save state / progression | Confirme `completedStepIds` et `storyFlags` comme sources techniques. | Inventorie storage, normalisation, mutations, lecture et risques de duplication. |
| GameState conditions | Identifie `ScriptCondition` et son evaluator comme socle existant. | Détaille les types de conditions et leur mapping vers conditions lisibles. |
| Read models / pickers | Confirme le besoin futur. | Détaille sources nécessaires, labels, tri, références cassées et consumers. |
| Package boundaries | Rappelle les limites à protéger. | Vérifie précisément les dépendances existantes et risques de couplage. |

P2-00 ne remplace pas P2-01.

## 7. Validation de la roadmap Phase 2

| Lot | Verdict | Raison | Risque | Dépendance |
|---|---|---|---|---|
| P2-00 — Roadmap Bootstrap / Domain Contract Audit | Garder, marqué terminé | Lot utile pour borner la phase et éviter une Phase 2 infinie. | Chevauchement avec P2-01 si le mot "audit" est compris comme inventaire détaillé. | Checkpoint Phase 1 |
| P2-01 — Existing Narrative Domain Inventory | Garder comme prochain lot exact | Indispensable avant tout contrat. | Démarrer des décisions de contrats avant d’avoir la vérité technique. | P2-00 |
| P2-02 — Story Step Descriptor / Storyline Metadata Decision | Garder, à challenger | La décision doit venir après inventaire des metadata et `completedStepIds`. | Créer un registry de steps trop tôt. | P2-01 |
| P2-03 — Event Authoring Source Contract | Garder | Les sources Event doivent être formalisées sans dupliquer le runtime. | Transformer Event en mini-Scene. | P2-01 |
| P2-04 — Scene / ScenarioAsset Adapter Contract | Garder | Sujet pivot : Scene pourrait être `ScenarioAsset`, wrapper ou adapter. | Créer un modèle parallèle inutile. | P2-01 |
| P2-05 — Outcome Reference Contracts | Garder | Outcomes Yarn / scenario doivent devenir sélectionnables et validables. | Créer un OutcomeRegistry prématuré. | P2-04 |
| P2-06 — Battle Reference / Outcome Contract | Garder | Minimal `victory` / `defeat` nécessaire pour la chaîne narrative. | Aspirer rewards, XP, money, static wild. | P2-04 |
| P2-07 — Fact Descriptor / Presentation Layer | Garder, à challenger fortement | Besoin de labels humains et consumers, mais l’état existe déjà ailleurs. | FactRegistry trop tôt ou duplication GameState. | P2-02, P2-05 |
| P2-08 — World Rule Predicate Adapter Contract | Garder, adapter d’abord | Les predicates existants ressemblent déjà à une base World Rule. | WorldRuleRegistry prématuré. | P2-07 |
| P2-09 — Narrative Validator Diagnostic Expansion | Garder | Les diagnostics donnent la valeur domaine avant l’UI finale. | Diagnostics non actionnables ou auto-correction implicite. | P2-02 à P2-08 |
| P2-10 — Reference Picker Read Models | Garder après diagnostics | Prépare Phase 4 sans créer de widgets. | Confondre read model et UI Flutter. | P2-09 |
| P2-CHECKPOINT-01 — Domain Contracts Readiness Review | Garder | Nécessaire pour décider Phase 3. | Clôturer avec migrations cachées ou contracts sans consumers. | P2-10 |

Verdict global : roadmap validée avec ajustement léger de wording sur P2-00 / P2-01.

## 8. Audit de cadrage de l’existant

| Zone | Rôle probable | Risque | Pourquoi P2-01 doit l’auditer précisément |
|---|---|---|---|
| `ScenarioAsset` | Substrat probable des Scenes, nodes, edges, outcomes et metadata. | Créer un wrapper Scene inutile ou casser le modèle existant. | Déterminer si Scene est un nom produit, un adapter ou un contrat distinct. |
| `ProjectManifest` | Agrégat projet : scenarios, dialogues, maps, trainers et autres assets. | Migration JSON trop tôt. | Identifier les besoins de persistence réels avant toute modification. |
| `GameState` / `SaveData` | Sources techniques pour `storyFlags`, `completedStepIds`, progression et metadata. | Dupliquer Fact / Step state. | Distinguer vérité stockée, vérité dérivée et présentation no-code. |
| `ScriptCondition` | Conditions existantes sur flags, variables, player/map/party/event. | Exposer une DSL technique aux auteurs. | Mapper vers conditions humaines et diagnostics. |
| `MapEntityRuntimePredicate` | Base probable de World Rule passive. | Créer WorldRuleRegistry alors qu’un adapter suffit peut-être. | Inventorier kinds, targets, fallback et conflits. |
| `NarrativeValidator` | Diagnostic narratif existant. | Multiplier les validators concurrents. | Déterminer les extensions prioritaires Phase 2. |
| `ProjectValidator` | Validation projet/scénario plus large. | Placer les diagnostics narratifs au mauvais niveau. | Clarifier séparation project validation / narrative validation. |
| `ScenarioRuntimeSourceEvent` | Sources runtime : map, trigger, entity interaction, outcome. | Dupliquer les sources auteur. | Formaliser Event Authoring Source sans conflit runtime. |
| `ScenarioRuntimeExecutor` / effects | Exécution runtime des scenarios et effets. | Démarrer Phase 3 trop tôt. | Comprendre les consumers sans les modifier. |
| Battle outcome flags runtime | Convention technique d’outcomes battle. | Faire du battle le moteur narratif principal. | Isoler le contrat minimal victory / defeat. |
| Global Story / Step Studio metadata runtime | Metadata existante autour chapters, steps et world presence. | Cacher la source de vérité dans metadata editor. | Décider descriptor, adapter ou migration. |
| Narrative workspace projection | Projection editor du workspace narratif. | Faire de `map_editor` la source de vérité domaine. | Séparer projection UI future et contrats purs. |
| Step Studio / Global Story Studio authoring | Workflows authoring existants ou partiels. | Confondre authoring metadata avec contrat stable. | Identifier ce qui est réutilisable sans sur-modéliser. |
| Project scenario use cases | Création / modification / suppression scenarios côté editor. | Coupler contrats domaine aux use cases editor. | Vérifier consumers réels avant nouveaux modèles. |

Cet audit reste volontairement un cadrage. Il ne documente pas tous les champs, formats metadata ou usages.

## 9. Zones techniques à inventorier en P2-01

| Fichier ou zone | Question à résoudre | Preuve attendue | Risque |
|---|---|---|---|
| `packages/map_core/lib/src/models/scenario_asset.dart` | Scene = `ScenarioAsset`, wrapper ou adapter ? | Champs, metadata, outcomes, nodes, edges, scopes, tests/usages. | Wrapper inutile. |
| `packages/map_core/lib/src/models/project_manifest.dart` | Quels assets sont persistés et comment référencer scenarios/dialogues/battles ? | Usages, champs, serialization, migrations existantes. | Migration prématurée. |
| `packages/map_core/lib/src/models/game_state.dart` | Quels états soutiennent Facts / availability ? | `storyFlags`, metadata, usages gameplay/runtime. | Duplications de vérité. |
| `packages/map_core/lib/src/models/save_data.dart` | `completedStepIds` et `storyFlags` suffisent-ils pour Step / Fact ? | Normalisation, persistence, read/write paths. | StepDescriptor redondant. |
| `packages/map_core/lib/src/models/script_conditions.dart` | Quelles conditions peuvent devenir lisibles no-code ? | Types, fields, validation, usages. | Conditions techniques exposées. |
| `packages/map_core/lib/src/models/map_entity_payloads.dart` | Les predicates couvrent-ils World Rule V0 ? | Kinds, target semantics, fallback. | WorldRuleRegistry prématuré. |
| `packages/map_core/lib/src/operations/narrative_validator.dart` | Quels diagnostics narratifs existent déjà ? | Types, severities, inputs, report shape. | Diagnostics dupliqués. |
| `packages/map_core/lib/src/validation/validators.dart` | Où placer les nouveaux diagnostics ? | Validation project/scenario et limites. | Mauvais niveau de validation. |
| `packages/map_gameplay/lib/src/game_state_mutations.dart` | Quelles mutations écrivent flags/steps ? | API, invariants, tests existants. | Scene / gameplay boundary floue. |
| `packages/map_gameplay/lib/src/script_condition_evaluator.dart` | Comment les conditions sont-elles évaluées ? | Mapping `ScriptCondition` -> `GameState`. | Divergence validator/runtime. |
| `packages/map_runtime/lib/src/application/scenario_runtime/` | Quels events/effects/outcomes runtime existent ? | Source events, executor, battle flags, continuation. | P2-03/P2-06 codés contre un modèle fantôme. |
| `packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart` | Quels predicates sont vraiment passifs ? | Read paths, no mutation, target assumptions. | World Rule devient Event. |
| `packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart` | Quelle metadata story/chapter/step est consommée ? | Extraction, ordering, fallback. | Storyline persistence mal placée. |
| `packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart` | Quelle présence monde dépend des steps ? | Metadata keys, predicates, completed steps. | Duplications World Rule. |
| `packages/map_editor/lib/src/features/narrative/` | Quelles projections et authoring metadata existent ? | Documents, metadata keys, diagnostics locaux. | Editor source de vérité domaine. |
| `packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart` | Quels use cases manipulent ScenarioAsset ? | Entrées/sorties, validation, persistence. | Contrats couplés à l’editor. |

## 10. Contrats candidats confirmés / à challenger

| Contrat candidat | Statut P2-00 | Raison | Consumer attendu |
|---|---|---|---|
| Story Step Descriptor | À challenger | `completedStepIds` et metadata Step Studio existent déjà. | Validator, pickers, authoring Phase 4. |
| Storyline metadata | À challenger | Storyline / Chapter peuvent rester metadata ou adapter si persistence dédiée non prouvée. | Validator, navigation editor, pickers. |
| Event Authoring Source | Confirmé | Besoin de sources auteur sans IDs bruts. | Validator, editor workflows, runtime bridge. |
| Scene / ScenarioAsset Adapter | Confirmé | La décision Scene est pivot Phase 2. | Validator, editor, runtime execution. |
| Outcome Reference Contract | Confirmé | Outcomes doivent être déclarés, consommés et diagnostiqués. | Scene adapter, validator, pickers. |
| Battle Reference / Outcome Contract | Confirmé minimal | `victory` / `defeat` suffisent au démarrage. | Scene, validator, runtime bridge. |
| Fact Descriptor / Presentation Layer | Confirmé mais registry à challenger | Besoin de labels humains sans dupliquer le GameState. | Validator, world rules, pickers, authoring. |
| World Rule Predicate Adapter | Confirmé comme adapter d’abord | Predicates existants sont la piste la plus prudente. | Runtime predicates, validator, editor authoring. |
| Validator diagnostics | Confirmé | Diagnostics avant UI et avant contrats persistants lourds. | map_core, editor, future CI/project validation. |
| Reference Picker Read Models | Confirmé plus tard | Nécessaire pour Phase 4, mais après inventaire et diagnostics. | map_editor workflows, no-code pickers. |
| Reward Model | À reporter | Money / XP / reward unifié restent gaps gameplay. | Phase 5 potentielle. |
| Quest Journal / Quest Engine | À reporter / refuser maintenant | Side quest V0 = Storyline secondaire. | Phase future si besoin UI/runtime prouvé. |

## 11. Risques de sur-modélisation

| Risque | Garde-fou |
|---|---|
| Créer trop de descriptors. | Exiger consumer, source de vérité, diagnostic et tests avant création. |
| Dupliquer `ScenarioAsset`. | P2-01 doit trancher Scene = nom produit, adapter ou wrapper avant P2-04. |
| Dupliquer `completedStepIds`. | Séparer storage technique, descriptor lisible et Fact dérivé. |
| Créer FactRegistry trop tôt. | Commencer par Fact Descriptor / Presentation Layer si les consumers sont clairs. |
| Créer WorldRuleRegistry trop tôt. | Adapter les predicates existants avant de créer un registry. |
| Modifier `ProjectManifest` trop tôt. | Ne persister que si migration et consumers sont justifiés. |
| Mettre l’UI dans Phase 2. | P2-10 produit des read models, pas de widgets. |
| Aspirer rewards, money, XP. | Reporter Reward Model et progression post-battle hors Phase 2. |
| Aspirer Selbrume réel. | Selbrume reste mapping conceptuel jusqu’à une phase dédiée. |
| Transformer Validator en auto-correcteur. | Validator diagnostique seulement. |

## 12. Package boundaries à protéger

`map_core` :

- contrats purs éventuels ;
- diagnostics ;
- read models éventuels ;
- aucune dépendance Flutter / Flame.

`map_gameplay` :

- conditions et mutations `GameState` si nécessaires ;
- pas d’UI ;
- pas de Flame.

`map_runtime` :

- execution / adapters runtime plus tard ;
- ne devient pas source de vérité produit.

`map_editor` :

- workflows authoring et pickers UI plus tard ;
- ne devient pas source de vérité domaine.

`map_battle` :

- reste indépendant du Narrative Studio ;
- ne décide pas seul de la progression narrative.

Interdictions à préserver :

- `map_battle` ne dépend pas du Narrative Studio ;
- `map_core` ne dépend pas de Flutter ;
- `map_editor` ne devient pas source de vérité domaine ;
- runtime Flame ne devient pas source de vérité produit.

## 13. Stratégie tests / validations pour Phase 2

- P2-00 : pas de tests Dart / Flutter ; lot documentaire.
- P2-01 : pas de tests obligatoires si inventaire documentaire pur ; toute aide outillée doit rester justifiée et bornée.
- P2-02+ : tests pure Dart ciblés dès qu’un contrat, adapter ou diagnostic est créé.
- Diagnostics : tests unitaires par diagnostic, avec cas positif / warning / erreur.
- Adapters et read models : tests de tri stable, labels humains, références cassées et filtrage.
- JSON / migrations : seulement si persistence décidée explicitement.
- Runtime / Flame : hors Phase 2 sauf lot ultérieur explicitement dédié.

## 14. Ajustements recommandés de road_map_phase_2.md

Ajustement appliqué : clarification légère de wording.

La roadmap indiquait que P2-00 devait "auditer précisément les structures existantes". Cette formulation risquait de faire glisser P2-00 dans P2-01. Elle a été remplacée par une formulation de cadrage :

```text
P2-00 cadre l’audit.
P2-01 fait l’inventaire détaillé.
```

Autres changements appliqués :

- P2-00 marqué terminé ;
- P2-01 marqué prochain lot exact ;
- ajout d’un résumé P2-00 dans la roadmap ;
- ajout des fichiers créés/modifiés, commandes exécutées, décisions et changements de périmètre ;
- précision de la frontière P2-01.

Aucun ajustement de lot, fusion ou déplacement n’est recommandé à ce stade.

## 15. Spécification attendue pour P2-01

Objectif :
Produire l’inventaire technique détaillé du domaine narratif existant avant toute création de contrat.

Sources à lire :

- roadmaps actives ;
- rapports Phase 1 et P2-00 ;
- rapports NS-GS utiles ;
- zones code listées dans la section 9.

Fichiers à inventorier :

- `scenario_asset.dart` ;
- `project_manifest.dart` ;
- `game_state.dart` ;
- `save_data.dart` ;
- `script_conditions.dart` ;
- `map_entity_payloads.dart` ;
- `narrative_validator.dart` ;
- `validators.dart` ;
- `game_state_mutations.dart` ;
- `script_condition_evaluator.dart` ;
- `scenario_runtime/` ;
- `map_entity_runtime_predicate_evaluator.dart` ;
- `global_story_chapter_runtime.dart` ;
- `step_studio_world_presence_runtime.dart` ;
- `map_editor/lib/src/features/narrative/` ;
- `project_scenario_use_cases.dart`.

Questions à résoudre :

- Scene est-elle `ScenarioAsset`, adapter ou wrapper ?
- Quelles metadata narratives existent déjà ?
- Quels states soutiennent Facts, Steps et availability ?
- Quels predicates peuvent devenir World Rules ?
- Quels diagnostics existent déjà ?
- Quels contracts ont vraiment des consumers ?
- Quels champs sont persistés et quels champs sont dérivés ?

Non-objectifs :

- pas de contrat créé ;
- pas de modèle `map_core` ;
- pas de JSON ;
- pas de migration ;
- pas de test créé sauf justification explicite d’un audit outillé ;
- pas de P2-02 démarré.

Livrable attendu :

```text
reports/roadmap/phase_2/p2_01_existing_narrative_domain_inventory.md
```

Evidence Pack attendu :

- `git status --short` initial et final ;
- fichiers lus ;
- commandes exécutées ;
- `git diff --check` ;
- `git diff --stat` ;
- `git diff --name-only` ;
- confirmation d’absence de code modifié.

Critères d’acceptation P2-01 :

- inventaire détaillé mais borné ;
- aucune création de contrat ;
- aucune modification de package ;
- vérité technique séparée des recommandations ;
- décisions à trancher en P2-02+ clairement listées.

## 16. Décisions à valider par l’utilisateur

- La roadmap Phase 2 est-elle validée telle quelle après clarification P2-00 / P2-01 ?
- P2-00 / P2-01 doivent-ils rester séparés ? Recommandation P2-00 : oui.
- Faut-il fusionner certains lots Phase 2 ? Recommandation P2-00 : non à ce stade.
- P2-01 doit-il commencer par `ScenarioAsset` ou par Step / metadata ? Recommandation P2-00 : commencer par `ScenarioAsset`, puis metadata Step / Global Story.
- Faut-il autoriser des read models outillés pendant P2-01 ? Recommandation P2-00 : seulement si l’inventaire documentaire devient impraticable sans eux.

## 17. Mise à jour de road_map_phase_2.md

`MVP Selbrume/road_map_phase_2.md` a été mise à jour pour indiquer :

- `P2-00 : ✅ terminé` ;
- `P2-01 : 🔜 prochain lot exact` ;
- résumé court du résultat P2-00 ;
- fichiers créés/modifiés ;
- commandes exécutées ;
- décisions ouvertes ;
- changement de périmètre : aucun, clarification seulement.

`MVP Selbrume/road_map_global.md` n’a pas été modifiée.

## 18. Evidence Pack

### 18.1 git status initial

```text
Sortie vide — aucun changement détecté au début du lot.
```

### 18.2 Fichiers lus

```text
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_2.md
MVP Selbrume/road_map_phase_1.md
reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md
reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md
reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md
reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md
reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md
reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md
reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
MVP Selbrume/road_map.md
MVP Selbrume/narrative_studio.md
MVP Selbrume/selbrume.md
reports/roadmap/pokemap_full_product_phased_roadmap_v1.md
reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md
reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md
reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md
reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md
reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
packages/map_core/lib/src/models/scenario_asset.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/models/script_conditions.dart
packages/map_core/lib/src/models/map_entity_payloads.dart
packages/map_core/lib/src/operations/narrative_validator.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/lib/src/script_condition_evaluator.dart
packages/map_runtime/lib/src/application/scenario_runtime/
packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart
packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart
packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart
packages/map_editor/lib/src/features/narrative/
packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
```

### 18.3 Fichiers créés

```text
reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
```

### 18.4 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_2.md
```

### 18.5 Commandes exécutées

```text
git status --short --untracked-files=all
test -f "MVP Selbrume/road_map_phase_2.md" && echo "phase2 roadmap present"; test -f "reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md" && echo "checkpoint report present"; test -d "reports/roadmap/phase_2" && echo "phase2 reports dir present" || echo "phase2 reports dir absent"
sed -n '1,260p' "MVP Selbrume/road_map_global.md"
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
rg -n ... "MVP Selbrume/road_map_phase_1.md" reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md
rg -n ... reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md
rg -n ... "MVP Selbrume/road_map.md" "MVP Selbrume/narrative_studio.md" "MVP Selbrume/selbrume.md" reports/roadmap/pokemap_full_product_phased_roadmap_v1.md reports/gameplay/ns_gs/ns_gs_checkpoint_01_mechanics_first_completion_review.md reports/gameplay/ns_gs/ns_gs_12_bis_evidence_pack_and_level_label_fix.md reports/gameplay/ns_gs/ns_gs_13_narrative_validator_minimal_v0.md reports/gameplay/ns_gs/ns_gs_16_side_quest_optional_storyline_readiness.md reports/gameplay/ns_gs/ns_gs_18_reward_money_xp_bridge_audit.md
rg --files packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/lib/src/validation packages/map_gameplay/lib/src packages/map_runtime/lib/src/application packages/map_editor/lib/src/features/narrative packages/map_editor/lib/src/application/use_cases
rg -n ... packages/map_core/lib/src/models/scenario_asset.dart packages/map_core/lib/src/models/project_manifest.dart packages/map_core/lib/src/models/game_state.dart packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/script_conditions.dart packages/map_core/lib/src/models/map_entity_payloads.dart packages/map_core/lib/src/operations/narrative_validator.dart packages/map_core/lib/src/validation/validators.dart
rg -n ... packages/map_gameplay/lib/src/game_state_mutations.dart packages/map_gameplay/lib/src/script_condition_evaluator.dart packages/map_runtime/lib/src/application/scenario_runtime packages/map_runtime/lib/src/application/map_entity_runtime_predicate_evaluator.dart packages/map_runtime/lib/src/application/global_story_chapter_runtime.dart packages/map_runtime/lib/src/application/step_studio_world_presence_runtime.dart packages/map_editor/lib/src/features/narrative packages/map_editor/lib/src/application/use_cases/project_scenario_use_cases.dart
sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"
find .. -name AGENTS.md -print
ls -la reports/roadmap && ls -la reports/roadmap/phase_1
sed -n '261,520p' "MVP Selbrume/road_map_phase_2.md"
mkdir -p reports/roadmap/phase_2
git diff --check
git diff --no-index --check /dev/null reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md || true
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff -- "MVP Selbrume/road_map_phase_2.md"
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
wc -l reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md "MVP Selbrume/road_map_phase_2.md"
nl -ba reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md | sed -n '548,680p'
rg -n "A COMPLETER|P2-01 report|P2-01 — Existing Narrative Domain Inventory" reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md "MVP Selbrume/road_map_phase_2.md"
sed -n '500,705p' reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
```

### 18.6 git diff --check

```text
```

### 18.7 git diff --stat

```text
 MVP Selbrume/road_map_phase_2.md | 68 +++++++++++++++++++++++++++++++++-------
 1 file changed, 56 insertions(+), 12 deletions(-)
```

### 18.8 git diff --name-only

```text
MVP Selbrume/road_map_phase_2.md
```

### 18.9 git status final

```text
 M "MVP Selbrume/road_map_phase_2.md"
?? reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md
```

### 18.10 Tests / analyze

```text
Non exécutés — P2-00 est documentaire et ne modifie aucun code.
```

### 18.11 git diff --no-index --check du rapport créé

```text
```

### 18.12 Diff complet de road_map_phase_2.md

```diff
diff --git a/MVP Selbrume/road_map_phase_2.md b/MVP Selbrume/road_map_phase_2.md
index bf070913..b23748c9 100644
--- a/MVP Selbrume/road_map_phase_2.md
+++ b/MVP Selbrume/road_map_phase_2.md
@@ -4,16 +4,16 @@

 Phase 2 — Domain Model & Contracts

-Statut : 🔜 Prête à démarrer
+Statut : 🔜 En cours

-Lot courant : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
+Lot courant : P2-01 — Existing Narrative Domain Inventory

-Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
+Prochain lot exact : P2-01 — Existing Narrative Domain Inventory

 Suivi des lots :

-- 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
-- P2-01 — Existing Narrative Domain Inventory
+- ✅ P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
+- 🔜 P2-01 — Existing Narrative Domain Inventory
 - P2-02 — Story Step Descriptor / Storyline Metadata Decision
 - P2-03 — Event Authoring Source Contract
 - P2-04 — Scene / ScenarioAsset Adapter Contract
@@ -25,7 +25,9 @@ Suivi des lots :
 - P2-10 — Reference Picker Read Models
 - P2-CHECKPOINT-01 — Domain Contracts Readiness Review

-P2-00 : 🔜 prochain lot exact
+P2-00 : ✅ terminé
+
+P2-01 : 🔜 prochain lot exact

 ## 2. Objectif de la Phase 2

@@ -122,13 +124,49 @@ Exclus :

 ## 7. Lots Phase 2 proposés

-### 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
+### ✅ P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

 Objectif :
-Vérifier le découpage Phase 2, auditer précisément les structures existantes et
-confirmer les premiers lots de contrats.
+Vérifier le découpage Phase 2, cadrer l’audit domaine, clarifier la frontière
+avec P2-01 et confirmer les premiers lots de contrats sans inventaire exhaustif.
+
+Résultat :
+P2-00 valide la roadmap Phase 2 avec une réserve de wording : P2-00 cadre
+l’audit, tandis que P2-01 fera l’inventaire détaillé. Le lot confirme
+l’approche audit-first, liste les zones à inventorier et prépare P2-01 sans
+créer de contrat ni modifier de code.
+
+Fichiers créés :
+
+- `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`
+
+Fichiers modifiés :
+
+- `MVP Selbrume/road_map_phase_2.md`
+
+Commandes exécutées :
+
+- `git status --short --untracked-files=all`
+- `test -f "MVP Selbrume/road_map_phase_2.md" ...`
+- `sed -n '1,260p' "MVP Selbrume/road_map_global.md"`
+- `sed -n '1,260p' "MVP Selbrume/road_map_phase_2.md"`
+- `sed -n '261,520p' "MVP Selbrume/road_map_phase_2.md"`
+- `rg -n ...` sur les rapports Phase 1 et documents de contexte
+- `rg --files ...` sur les zones code candidates
+- `rg -n ...` sur les zones code candidates
+- `find .. -name AGENTS.md -print`
+- `ls -la reports/roadmap && ls -la reports/roadmap/phase_1`
+- `mkdir -p reports/roadmap/phase_2`

-Fichiers probables à auditer :
+Décisions utilisateur nouvelles :
+Aucune décision nouvelle imposée. Les décisions ouvertes restent à valider
+pendant P2-01 ou les lots de contrats.
+
+Changements de périmètre :
+Aucun changement de périmètre. Clarification uniquement : P2-00 prépare la
+carte, P2-01 explore le territoire.
+
+Zones probables à inventorier en P2-01 :

 - `reports/roadmap/phase_1/*`
 - `MVP Selbrume/road_map_global.md`
@@ -152,12 +190,18 @@ pas de Selbrume final.
 Dépendances :
 P1-CHECKPOINT-01.

-### P2-01 — Existing Narrative Domain Inventory
+### 🔜 P2-01 — Existing Narrative Domain Inventory

 Objectif :
 Inventorier `ScenarioAsset`, metadata narrative, validators, runtime source
 events, predicates, save state et authoring projections.

+Frontière héritée de P2-00 :
+P2-01 doit produire l’inventaire technique détaillé que P2-00 a volontairement
+laissé hors scope : champs, usages, sources de vérité, conventions metadata,
+risques de migration et preuves exactes. P2-01 ne doit pas encore créer les
+contrats Phase 2.
+
 Risque :
 Sous-estimer les conventions déjà présentes dans metadata editor.

@@ -402,5 +446,5 @@ Phase 2 ne prouve pas le runtime Flame complet.
 Le prochain lot exact est :

 ```text
-P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
+P2-01 — Existing Narrative Domain Inventory
 ```
```

### 18.13 Contenu complet du rapport créé

Le contenu complet du rapport créé est le présent fichier.

### 18.14 Contrôle hors scope

Commande :

```text
git diff --name-only -- "MVP Selbrume/road_map_global.md" "MVP Selbrume/road_map_phase_1.md" packages examples/playable_runtime_host
```

Sortie exacte :

```text
```

## 19. Auto-review critique

Le lot a-t-il modifié uniquement ce qui était autorisé ?
Oui. Le lot crée un rapport documentaire Phase 2 et modifie seulement `MVP Selbrume/road_map_phase_2.md`.

Le rapport P2-00 existe-t-il au bon chemin ?
Oui : `reports/roadmap/phase_2/p2_00_phase_2_roadmap_bootstrap_domain_contract_audit.md`.

`road_map_phase_2.md` a-t-elle été mise à jour ?
Oui. P2-00 est marqué terminé et P2-01 devient le prochain lot exact.

`road_map_global.md` est-elle restée intacte ?
Oui, aucune modification volontaire n’a été faite sur `MVP Selbrume/road_map_global.md`.

Aucun code n’a-t-il été modifié ?
Oui. Les packages ont été inspectés en lecture seule.

Aucun test/analyze Dart/Flutter n’a-t-il été lancé ?
Oui. Aucun `dart test`, `flutter test`, `dart analyze` ou `flutter analyze` n’a été lancé.

P2-01 n’a-t-il pas été commencé ?
Oui. P2-00 liste les zones à inventorier, mais ne produit pas l’inventaire détaillé.

La frontière P2-00/P2-01 est-elle claire ?
Oui. P2-00 cadre l’audit ; P2-01 explore le territoire.

La roadmap Phase 2 reste-t-elle bornée ?
Oui. Aucun lot n’a été ajouté ; aucun élargissement de Phase 2 n’a été introduit.

Les risques de sur-modélisation sont-ils listés ?
Oui. Les risques FactRegistry, WorldRuleRegistry, Step registry, duplication `ScenarioAsset`, duplication `completedStepIds`, migration trop tôt, UI prématurée et Selbrume réel sont explicitement listés.

Le prochain lot exact est-il clair ?
Oui : `P2-01 — Existing Narrative Domain Inventory`.

### Regard critique sur le prompt

Le prompt est strict et utile. La seule ambiguïté réelle est le titre de P2-00 : "Domain Contract Audit" peut faire penser à un audit technique détaillé, alors que le corps du prompt demande un audit de cadrage. Cette ambiguïté est résolue dans le rapport et dans la roadmap par la formule :

```text
P2-00 prépare la carte.
P2-01 explore le territoire.
```
