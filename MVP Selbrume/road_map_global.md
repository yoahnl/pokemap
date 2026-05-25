# PokeMap Global Roadmap — Phased Product Roadmap

## 1. Statut global

Roadmap globale : active

Bloc NS-GS-01 → NS-GS-18 : ✅ terminé comme bloc mechanics-first Level 2 Application

Phase courante : Phase 5 — Gameplay Gaps Prioritaires

Roadmap de phase courante : `MVP Selbrume/road_map_phase_5.md`

Lot courant : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Prochain lot exact : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Suivi global :

- ROADMAP-GLOBAL-00 : ✅ terminé
- Phase 1 — Canonical Product Model / Narrative Studio Foundations : ✅ clôturée avec réserves mineures
- Phase 2 — Domain Model & Contracts : ✅ clôturée avec réserves mineures
- Phase 3 — Runtime / Application / Flame / Disk Validation : ✅ clôturée avec réserves mineures
- Phase 4 — Authoring Workflows Minimal : ✅ clôturée avec réserves mineures
- Phase 5 — Gameplay Gaps Prioritaires : 🔜 phase courante
- P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit : 🔜 prochain lot exact

## 2. Objectif final de PokeMap

Créer un outil moderne de création de fangame Pokémon-like,
no-code autant que possible,
proche d’un RPG Maker Pokémon-like,
permettant à une personne non développeuse de créer un jeu court, jouable, cohérent,
avec exploration, histoire, événements, dialogues, cinématiques, combats,
progression, quêtes annexes, sauvegarde, validation et runtime.

Le créateur doit pouvoir penser en :

- situations ;
- événements ;
- scènes ;
- décisions ;
- conséquences ;
- progression ;
- faits du monde ;
- règles visibles du monde.

La grammaire produit cible reste :

```text
Quand [déclencheur]
Si [conditions]
Alors [actions / scène / dialogue / combat / cinématique]
Puis [conséquences / faits / changements du monde]
```

## 3. Gouvernance par phases

Gouvernance active :

```text
Objectif final
→ Phases majeures
→ Roadmap détaillée uniquement pour la phase active
→ Exécution des lots de phase
→ Checkpoint de fin de phase
→ Mise à jour de road_map_global.md
→ Décision utilisateur
→ Création ou mise à jour de la roadmap de phase suivante
```

Règle importante :

```text
On ne maintient pas une roadmap infinie de 80 lots.
La roadmap globale décrit les phases.
La roadmap de phase décrit les lots précis de la phase active.
```

Chaque phase doit produire un checkpoint de fermeture indiquant :

- ce qui est prouvé ;
- ce qui reste partiel ;
- ce qui est non prouvé ;
- ce qui est reporté ;
- la phase suivante recommandée ;
- le prochain lot exact.

## 4. Relation entre les roadmaps

`MVP Selbrume/road_map_global.md`
→ source de vérité globale par phases.

`MVP Selbrume/road_map_phase_1.md`
→ source de vérité détaillée pour la Phase 1.

`MVP Selbrume/road_map_phase_2.md`
→ source de vérité détaillée pour la Phase 2 clôturée.

`MVP Selbrume/road_map_phase_3.md`
→ source de vérité détaillée pour la Phase 3 clôturée.

`MVP Selbrume/road_map_phase_4.md`
→ source de vérité détaillée pour la Phase 4 clôturée.

`MVP Selbrume/road_map_phase_5.md`
→ source de vérité détaillée pour la Phase 5 courante.

`MVP Selbrume/road_map.md`
→ roadmap historique NS-GS clôturée, conservée comme archive de preuves et contexte.

`reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`
→ rapport stratégique long qui a proposé cette gouvernance.

`reports/roadmap/phase_1/*.md`
→ livrables et rapports des lots Phase 1.

`reports/roadmap/phase_2/*.md`
→ livrables et rapports des lots Phase 2.

## 5. Synthèse des phases

- ✅ Phase 0 — Audit global & roadmap reset
- ✅ Phase 1 — Canonical Product Model / Narrative Studio Foundations
- ✅ Phase 2 — Domain Model & Contracts
- ✅ Phase 3 — Runtime / Application / Flame / Disk Validation
- ✅ Phase 4 — Authoring Workflows Minimal
- 🔜 Phase 5 — Gameplay Gaps Prioritaires
- Phase 6 — Selbrume Golden Slice réel
- Phase 7 — UI / UX moderne finale

## 6. Phase 0 — Audit global & roadmap reset

Objectif :
Figer l’objectif final, l’état actuel, les gaps, les phases et la méthode de gouvernance.

Pourquoi :
Le bloc NS-GS-01 → NS-GS-18 a produit beaucoup de preuves mechanics-first, mais
la suite devait sortir d’une roadmap infinie et passer à une gouvernance par phases.

Préconditions :

- rapports NS-GS disponibles ;
- documents Narrative Studio et Selbrume disponibles ;
- décision utilisateur : UI moderne tardive.

Périmètre :

- audit stratégique ;
- matrice des acquis et gaps ;
- proposition de phases ;
- recommandation de prochaine phase.

Non-objectifs :

- pas de code ;
- pas de tests ;
- pas d’UI ;
- pas de NS-GS-19 ;
- pas de contenu Selbrume.

Livrables :

- `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`

Critères de sortie :

- phases définies ;
- prochaine phase recommandée ;
- prochain lot exact recommandé ;
- evidence pack complet.

Checkpoint final :

- ROADMAP-01 — PokeMap Full Product Audit & Phased Master Roadmap Proposal

Statut :
✅ terminé.

## 7. Phase 1 — Canonical Product Model / Narrative Studio Foundations

Objectif :
Stabiliser les concepts produit et les frontières du futur Narrative Studio :
Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact,
World Rule et Validator.

Pourquoi :
Le bloc NS-GS a prouvé beaucoup de mécaniques au niveau application, mais il n’a
pas figé le vocabulaire produit canonique. Avant de coder de nouveaux modèles ou
de lancer une UI moderne, il faut verrouiller les responsabilités et frontières.

Préconditions :

- Phase 0 terminée ;
- `MVP Selbrume/road_map_phase_1.md` créée ;
- UI moderne confirmée comme phase tardive ;
- Selbrume traité comme référence, pas comme contenu à générer.

Périmètre :

- modèle produit canonique ;
- frontières Event / Scene / Cinematic ;
- grammaire Fact / World Rule ;
- structure Storyline / Chapter / Story Step ;
- mapping Selbrume de référence ;
- workflows no-code minimaux ;
- proposition Phase 2.

Non-objectifs :

- pas de code de production ;
- pas de modèles Freezed/JsonSerializable ;
- pas de build_runner ;
- pas de modification ProjectManifest ;
- pas de UI moderne ;
- pas de Reward Model ;
- pas de Quest Engine ;
- pas de contenu Selbrume final ;
- pas de project.json Selbrume.

Livrables :

- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`
- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`
- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`
- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`
- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md`
- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`
- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`

Critères de sortie :

- chaque concept Phase 1 est défini ;
- les confusions Event / Scene / Cinematic / Yarn / Fact / World Rule sont fermées ;
- Selbrume est mappé comme référence sans création de contenu ;
- les workflows no-code minimaux sont décrits ;
- les lots Phase 2 sont proposés ;
- `road_map_global.md` est mis à jour au checkpoint de fin de phase.

Checkpoint final :

- P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

Statut :
✅ clôturée avec réserves mineures.

Résultat checkpoint :

```text
Phase 1 a figé la grammaire produit du Narrative Studio :
Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact,
World Rule, Validator, mapping Selbrume, workflows no-code et proposition
Phase 2.
```

Réserves :

- Phase 1 reste documentaire, pas runtime ;
- les preuves Level 3 Flame et Level 4 projet disque restent reportées ;
- les contrats domaine, JSON, migrations, authoring minimal et UI restent à
  traiter dans les phases suivantes.

## 8. Phase 2 — Domain Model & Contracts

Objectif :
Définir ou stabiliser les contrats, descriptors, adapters, read models et
diagnostics nécessaires au Narrative Studio, en partant de l’existant avant de
créer de nouveaux modèles.

Pourquoi :
Les concepts Phase 1 devront devenir des contrats stables, testables et
réutilisables par editor, runtime et validator.

Préconditions :

- Phase 1 terminée ;
- concepts et frontières validés ;
- lots Phase 2 proposés par P1-CHECKPOINT-01.

Périmètre :

- audit de l’existant narratif ;
- contrats pure Dart si nécessaires ;
- adapters/read models lorsque le stockage existe déjà ;
- diagnostics et validators associés ;
- compatibilité avec `ScenarioAsset` existant ;
- stratégie persistence / JSON / migration explicite.

Non-objectifs :

- pas d’UI moderne ;
- pas de Flame harness complet ;
- pas de Reward Engine ;
- pas de contenu Selbrume final.

Livrables :

- `MVP Selbrume/road_map_phase_2.md` ;
- contrats domaine validés, adaptés ou explicitement reportés ;
- tests ciblés ;
- rapport checkpoint Phase 2.

Critères de sortie :

- les concepts Phase 1 ont un support contractuel ou un report explicite ;
- les migrations ou compatibilités sont documentées ;
- les diagnostics structuraux nécessaires sont testés.

Checkpoint final :

- P2-CHECKPOINT-01 — Domain Contracts Readiness Review

Statut :
✅ clôturée avec réserves mineures.

Résultat checkpoint :

```text
Phase 2 a stabilisé les décisions domaine du Narrative Studio, ajouté un
premier batch de diagnostics dans map_core et créé les premiers read models
purs de picker sans registry, sans UI et sans migration ProjectManifest.
```

Livrables principaux :

- rapports P2-00 à P2-10 ;
- `reports/roadmap/phase_2/p2_checkpoint_01_domain_contracts_readiness_review.md` ;
- diagnostics `declaredOutcomeNeverEmitted`, `emitOutcomeNotDeclared`,
  `visibilityRuleConditionalMissingPredicate`, `worldRulePredicateEmptyRefId`,
  `scenarioChoiceNodeRuntimeUnsupported` ;
- read models `NarrativeScenarioPickerOption`, `NarrativeOutcomePickerOption`,
  `NarrativeBattleReferencePickerOption` ;
- `MVP Selbrume/road_map_phase_3.md`.

Réserves :

- pas encore de preuve runtime Flame ;
- pas encore de preuve projet disque ;
- pas encore d'UI authoring ;
- pickers Story Step / Fact / World Rule / Event Source reportés ;
- Selbrume reste conceptuel.

## 9. Phase 3 — Runtime / Application / Flame / Disk Validation

Objectif :
Prouver le vrai chemin d’exécution :
Event → Scene → Dialogue/Yarn outcome → Cinematic placeholder → Battle →
Fact/Step → World Rule → Save/Load.

Pourquoi :
Le bloc NS-GS a surtout prouvé le Level 2 Application. Le produit final doit
être validé dans `PlayableMapGame` et depuis un projet disque.

Préconditions :

- contrats Phase 2 suffisants ou adapters temporaires assumés ;
- Golden path générique clairement défini.

Périmètre :

- harness Flame / PlayableMapGame ;
- harness projet disque ;
- validation save/load ;
- preuve Level 2 / 3 / 4 honnête.

Non-objectifs :

- pas d’UI premium ;
- pas de contenu Selbrume final ;
- pas de génération automatique de jeu.

Livrables :

- roadmap vivante Phase 3 ;
- tests / smoke harness runtime ;
- rapport de validation Level 2 / 3 / 4 ;
- checkpoint Phase 3.

Critères de sortie :

- chemin générique prouvé au runtime ou gap explicite ;
- projet disque générique chargé et joué ou gap explicite ;
- les limites Flame/disk/editor ne sont plus ambiguës.

Checkpoint final :

- P3-CHECKPOINT-01 — Runtime & Disk Readiness Review

Statut :
✅ clôturée avec réserves mineures.

Résultat de clôture :

- `project.json -> RuntimeMapBundle -> PlayableMapGame` prouvé par slices
  techniques ciblées ;
- `ScenarioAsset` chargé depuis disque et exécuté ;
- sources Event runtime, continuation outcome / battle outcome, projections
  passives, save/load narratif et smoke host minimal validés ;
- réserves conservées : pas d'UI authoring, pas de boucle joueur complète,
  pas de combat complet, pas de rewards / money / XP, pas de Selbrume final.

## 10. Phase 4 — Authoring Workflows Minimal

Objectif :
Rendre les mécaniques authorables de manière fonctionnelle, même sans UI premium :
events, scenes, conditions, facts, steps, world rules, battle refs et item refs.

Pourquoi :
Le produit doit permettre à un créateur non développeur d’utiliser les briques
prouvées sans éditer du JSON brut ni manipuler des IDs techniques partout.

Préconditions :

- Phase 1 terminée ;
- Phase 2 et Phase 3 clôturées avec réserves mineures.

Périmètre :

- workflows minimaux ;
- pickers et validations simples ;
- intégration fonctionnelle du validator si possible ;
- documentation des limites no-code.

Non-objectifs :

- pas de design system final ;
- pas de Scene Builder visuel complet ;
- pas de Cinematic Builder visuel complet ;
- pas de contenu Selbrume final.

Livrables :

- roadmap vivante Phase 4 ;
- workflows authoring minimaux ;
- preuves fonctionnelles ciblées ;
- checkpoint Phase 4.

Critères de sortie :

- un créateur peut authorer un mini-flow générique sans JSON brut ;
- les références cassées sont diagnostiquées avant runtime ;
- les gaps UX premium sont reportés à Phase 7.

Checkpoint final :

- P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Statut :
✅ clôturée avec réserves mineures.

Résultat de clôture :

- read models et pickers narratifs V0 prouvés côté `map_core` ;
- draft scenario minimal, opérations Event Source, operations Outcome/Battle,
  drafts Predicate/World Rule et adapter diagnostics authoring prouvés par
  tests purs ;
- golden path authoring minimal P4-07 validant le chaînage
  read models -> draft -> source -> outcome -> predicate -> compilation ->
  diagnostics authoring ;
- réserves conservées : pas d'UI editor interactive, pas de preuve disque P4,
  pas de runtime P4, pas de produit final, pas de Scene Builder/Cinematic
  Builder, pas de Selbrume final.

## 11. Phase 5 — Gameplay Gaps Prioritaires

Objectif :
Traiter les gaps nécessaires pour une boucle fangame jouable : rewards, money,
XP, static wild encounter, hasItem direct, door/warp conditionnel et autres gaps
RPG prioritaires.

Pourquoi :
Un fangame court jouable exige une boucle combat → reward/progression → monde →
save/load plus complète que le bloc NS-GS actuel.

Préconditions :

- modèle produit stabilisé ;
- workflows authoring minimaux orientent les besoins gameplay ;
- NS-GS-18 reclassé comme audit de gaps rewards.
- Phase 4 clôturée avec réserves mineures.

Périmètre :

- Reward Model Minimal Design si validé ;
- money bridge ;
- XP / level-up design puis implémentation bornée ;
- static wild authorable ;
- `hasItem` direct si validé ;
- door/warp conditionnel minimal.

Non-objectifs :

- pas de reward engine énorme ;
- pas de parité Pokémon complète ;
- pas d’UI premium ;
- pas de couplage battle → narration.

Livrables :

- roadmap vivante Phase 5 ;
- sous-roadmaps courtes ;
- tests mechanics-first ;
- checkpoint Phase 5.

Critères de sortie :

- boucle RPG courte raisonnable prouvée ou gaps résiduels classés ;
- rewards/money/XP ne sont plus confondus avec facts/steps ;
- le scope gameplay reste borné.

Checkpoint final :

- P5-CHECKPOINT-01 — Gameplay Loop Readiness Review

Statut :
🔜 phase courante.

## 12. Phase 6 — Selbrume Golden Slice réel

Objectif :
Créer ou valider, par l’utilisateur dans l’éditeur, le premier vrai Golden Slice
Selbrume, sans que l’agent génère tout le jeu à sa place.

Pourquoi :
Selbrume est le scénario de référence qui vérifie la grammaire complète avec un
cas concret, mais il doit rester un test du produit, pas un contenu fabriqué par
l’agent dans le repo.

Préconditions :

- Phase 1 terminée ;
- Phase 3 runtime/disk suffisamment solide ;
- Phase 4 authoring minimal disponible ;
- gaps gameplay bloquants traités ou assumés.

Périmètre :

- checklist auteur ;
- validation d’un projet réel ;
- smoke runtime ;
- corrections génériques si le projet révèle des gaps.

Non-objectifs :

- ne pas générer Selbrume automatiquement ;
- ne pas finaliser tout le mini-jeu ;
- ne pas produire toutes les maps, PNJ, dialogues et trainers.

Livrables :

- roadmap vivante Phase 6 ;
- Golden Slice créé ou validé par l’utilisateur ;
- rapport Level 3 / 4 ;
- checkpoint Phase 6.

Critères de sortie :

- le scénario “Lysa au port” est réellement authoré et jouable ;
- le validator confirme les références principales ;
- le runtime charge et exécute le projet disque.

Checkpoint final :

- P6-CHECKPOINT-01 — Selbrume Golden Slice Validation Review

Statut :
future.

## 13. Phase 7 — UI / UX moderne finale

Objectif :
Refondre ou construire l’UI moderne et premium : App Shell, Narrative Studio,
Scene Builder, Storyline Graph, Cinematic Builder et Validator UI.

Pourquoi :
L’UI finale doit servir un modèle produit prouvé, pas compenser des concepts
flous. La décision utilisateur place cette refonte parmi les dernières grandes
phases.

Préconditions :

- modèle produit stabilisé ;
- contrats domaine suffisamment solides ;
- runtime/disk et workflows authoring prouvés ;
- retour d’un Golden Slice réel si possible.

Périmètre :

- Modern App Shell ;
- Narrative Studio premium ;
- Storyline Board / Graph ;
- Event Builder ;
- Scene Builder ;
- Cinematic Builder ;
- Facts & World Rules UI ;
- Validator UI ;
- UX no-code guidée.

Non-objectifs :

- ne pas inventer de nouvelles mécaniques dans la UI ;
- ne pas masquer les gaps runtime ;
- ne pas exposer les flags techniques comme expérience principale.

Livrables :

- roadmap vivante Phase 7 ;
- design system final ou stabilisé ;
- composants UI ;
- tests widget / interaction ;
- checkpoint Phase 7.

Critères de sortie :

- un créateur non développeur peut authorer, diagnostiquer et comprendre son
  fangame court dans une UI moderne.

Checkpoint final :

- P7-CHECKPOINT-01 — Modern UI Product Readiness Review

Statut :
future tardive.

## 14. Phase courante

Phase courante :
Phase 5 — Gameplay Gaps Prioritaires

Roadmap de phase :
`MVP Selbrume/road_map_phase_5.md`

Prochain lot de la phase :
P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Note :
P4-CHECKPOINT-01 a clôturé Phase 4 et créé la roadmap vivante Phase 5. Il ne
démarre pas P5-00.

## 15. Prochain lot exact

P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

P5-00 doit rester audit-first et cadrer la boucle RPG minimale : New Game,
GameState initial, party, bag, heal center, rewards/money/XP, capture,
save/load gameplay et validation de jouabilité.

P5-00 ne doit pas créer de contenu Selbrume final, ne doit pas lancer l'UI
premium, ne doit pas implémenter rewards/money/XP en code pendant l'audit et ne
doit pas transformer la Phase 5 en parité Pokémon complète.

## 16. Critères de changement de phase

Une phase peut être fermée uniquement si :

- tous les lots prévus de la phase sont terminés ou explicitement reclassés ;
- le checkpoint de phase existe ;
- les preuves principales sont listées ;
- les limites restantes sont honnêtement classées ;
- `MVP Selbrume/road_map_global.md` est mis à jour ;
- la prochaine phase est choisie ou confirmée ;
- la roadmap vivante de la phase suivante est créée ou mise à jour ;
- le prochain lot exact est fixé ;
- l’utilisateur valide le passage de phase.

Une phase ne doit pas être fermée si :

- des ambiguïtés centrales restent maquillées ;
- le checkpoint manque ;
- la roadmap globale n’est pas mise à jour ;
- la phase suivante est démarrée sans validation utilisateur.

## 17. Règle permanente de maintenance de cette roadmap globale

À chaque checkpoint de fin de phase, l’agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire la roadmap vivante de la phase en cours.
3. Lire le rapport checkpoint de la phase.
4. Mettre à jour le statut de la phase terminée.
5. Ajouter un résumé court du résultat de phase.
6. Ajouter les livrables principaux produits pendant la phase.
7. Ajouter les preuves principales et limites restantes.
8. Mettre à jour les gaps globaux.
9. Choisir ou confirmer la phase suivante.
10. Créer ou mettre à jour la roadmap vivante de la phase suivante.
11. Mettre à jour la section “Phase courante”.
12. Mettre à jour la section “Prochain lot exact”.
13. Signaler toute décision utilisateur nouvelle.
14. Ne jamais démarrer la phase suivante sans validation utilisateur.
15. Ne jamais créer de contenu Selbrume final sauf demande explicite.
16. Ne jamais traiter cette roadmap globale comme une liste infinie de lots.

À chaque lot de phase, l’agent lit `road_map_global.md` pour contexte,
mais il ne la modifie pas sauf si le lot est un checkpoint de fin de phase
ou si l’utilisateur le demande explicitement.

## 18. Décisions utilisateur intégrées

- La refonte UI moderne / premium est une phase tardive.
- Selbrume est un scénario de référence, pas du contenu à générer.
- Les roadmaps doivent être découpées par phases.
- Chaque phase a sa roadmap détaillée.
- À la fin de chaque phase, la roadmap globale doit être mise à jour.
- P1-01 ne doit pas démarrer avant que `road_map_global.md` existe.
- `MVP Selbrume/road_map.md` reste une roadmap historique NS-GS clôturée, pas
  une roadmap active infinie.

## 19. Gaps globaux suivis

- Level 3 Flame / PlayableMapGame Golden Slice complet : non entièrement prouvé.
- Level 4 projet disque / host narratif technique : prouvé partiellement en
  Phase 3 ; vrai projet créé dans l'éditeur non prouvé.
- Storyline / Chapter / Story Step contract ou descriptor : décision Phase 2 faite, picker V0 prouvé en Phase 4.
- Event authoring source contract : décision Phase 2 faite, picker et opérations V0 prouvés en Phase 4.
- Scene / ScenarioAsset adapter : décision Phase 2 faite, preuve runtime Phase 3.
- FactDescriptor / Fact Presentation Layer : décision Phase 2 faite, predicate references V0 prouvées en Phase 4 sans registry.
- World Rule Predicate Adapter : décision Phase 2 faite, preuve runtime Phase 3 et draft authoring passif V0 Phase 4.
- Validator UI et intégration authoring : adapter authoring prouvé en Phase 4, UI reportée Phase 7.
- Reward Model, money, XP, level-up : Phase 5.
- Static wild encounter authorable réel : Phase 5.
- Selbrume Golden Slice réel : Phase 6.
- UI / UX moderne finale : Phase 7.

## 20. Historique des mises à jour globales

- 2026-05-24 — ROADMAP-GLOBAL-00 — Roadmap globale vivante créée. Phase
  courante fixée à Phase 1 — Canonical Product Model / Narrative Studio
  Foundations. Prochain lot exact fixé à P1-01 — Canonical Narrative Product
  Model V1.
- 2026-05-24 — P1-CHECKPOINT-01 — Phase 1 clôturée avec réserves mineures.
  La grammaire produit du Narrative Studio est figée : Storyline, Chapter,
  Story Step, Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule,
  Validator, mapping Selbrume, workflows no-code et proposition Phase 2.
  Phase courante mise à jour vers Phase 2 — Domain Model & Contracts.
  Roadmap de phase courante fixée à `MVP Selbrume/road_map_phase_2.md`.
  Prochain lot exact fixé à P2-00 — Phase 2 Roadmap Bootstrap / Domain
  Contract Audit.
- 2026-05-25 — P2-CHECKPOINT-01 — Phase 2 clôturée avec réserves mineures.
  La Phase 2 a stabilisé les décisions domaine, refusé les registries
  prématurés, ajouté les diagnostics P2-09, ajouté les read models P2-10 et
  confirmé que la prochaine preuve doit être runtime/disk. Phase courante mise
  à jour vers Phase 3 — Runtime / Application / Flame / Disk Validation.
  Roadmap de phase courante fixée à `MVP Selbrume/road_map_phase_3.md`.
  Prochain lot exact fixé à P3-00 — Phase 3 Roadmap Bootstrap / Runtime & Disk
  Validation Audit.
- 2026-05-25 — P3-CHECKPOINT-01 — Phase 3 clôturée avec réserves mineures.
  La Phase 3 a prouvé le chemin runtime/disk par slices techniques :
  `ScenarioAsset` depuis `project.json`, sources Event runtime, continuation
  outcome / battle outcome, projections passives, save/load narratif et smoke
  host minimal `PlayableMapGame`. Les réserves restantes concernent l'UI
  authoring, l'input joueur complet, le combat complet, rewards / money / XP et
  Selbrume final. Phase courante mise à jour vers Phase 4 — Authoring Workflows
  Minimal. Roadmap de phase courante fixée à
  `MVP Selbrume/road_map_phase_4.md`. Prochain lot exact fixé à P4-00 — Phase 4
  Roadmap Bootstrap / Authoring Workflow Audit.
- 2026-05-25 — P4-CHECKPOINT-01 — Phase 4 clôturée avec réserves mineures.
  La Phase 4 a prouvé l'authoring minimal pur : read models / pickers,
  scenario draft, opérations Event Source, opérations Outcome/Battle, drafts
  Predicate/World Rule, adapter diagnostics authoring et golden path in-memory.
  Les réserves restantes concernent l'UI editor, le runtime/disque des
  workflows authoring, le produit final, Selbrume réel et les gaps gameplay.
  Phase courante mise à jour vers Phase 5 — Gameplay Gaps Prioritaires.
  Roadmap de phase courante fixée à `MVP Selbrume/road_map_phase_5.md`.
  Prochain lot exact fixé à P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop
  Audit.
