# Phase 4 Roadmap — Authoring Workflows Minimal

## 1. Statut de la phase

Phase 4 — Authoring Workflows Minimal

Statut : 🔜 Phase courante

Lot courant : P4-00 — Phase 4 Roadmap Bootstrap / Authoring Workflow Audit

Prochain lot exact : P4-00 — Phase 4 Roadmap Bootstrap / Authoring Workflow Audit

Suivi des lots :

- 🔜 P4-00 — Phase 4 Roadmap Bootstrap / Authoring Workflow Audit
- P4-01 — Narrative Reference Picker Coverage Review
- P4-02 — Scenario Authoring Minimal Workflow Design
- P4-03 — Event Source Authoring Minimal Workflow Design
- P4-04 — Outcome / Battle Outcome Authoring Minimal Workflow Design
- P4-05 — Fact / Predicate / World Rule Authoring Minimal Workflow Design
- P4-06 — Narrative Validator Integration Readiness
- P4-07 — Minimal Authoring Golden Path Proposal
- P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

P4-00 : 🔜 prochain lot exact

## 2. Objectif de la Phase 4

Rendre les mécaniques narratives prouvées en Phase 3 authorables de manière
fonctionnelle et no-code minimal, sans UI premium.

Phase 4 doit répondre à la question :

```text
Un créateur peut-il préparer un flux narratif minimal sans éditer directement
les graphes techniques ou les IDs bruts comme langage principal ?
```

## 3. Pourquoi cette phase existe

La Phase 3 a prouvé que les contrats domaine Phase 2 peuvent alimenter le disque
et le runtime. Elle n'a pas créé l'expérience d'authoring.

La Phase 4 doit transformer ces preuves en workflows auteur minimaux :

- choisir des références avec des pickers/read models ;
- construire ou décrire un scenario minimal ;
- choisir les sources Event runtime ;
- authorer outcomes et battle refs sans registry ;
- préparer facts, predicates et world rules passives ;
- intégrer les diagnostics existants avant runtime.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- Phase 2 clôturée avec réserves mineures.
- Phase 3 clôturée avec réserves mineures.
- `reports/roadmap/phase_3/p3_checkpoint_01_runtime_disk_readiness_review.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 4.
- Selbrume reste une référence conceptuelle, pas du contenu à générer.

## 5. Périmètre Phase 4

Inclus :

- audit des workflows authoring existants ;
- couverture des read models de pickers ;
- design de workflow minimal pour ScenarioAsset ;
- design de workflow minimal pour sources Event ;
- design de workflow minimal pour outcomes et battle outcomes ;
- design de workflow minimal pour facts, predicates et world rules passives ;
- préparation de l'intégration validator ;
- proposition d'un golden path authoring minimal ;
- checkpoint Phase 4.

Exclus :

- UI premium ;
- design system final ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- Selbrume final ;
- rewards, money, XP, level-up ;
- gameplay gaps Phase 5 ;
- migration ProjectManifest opportuniste ;
- registry persistant ;
- runtime/disk proof supplémentaire hors besoin P4 explicite.

## 6. Règles de maintenance

À chaque lot Phase 4, l'agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_4.md`.
3. Respecter le prochain lot exact.
4. Ne pas démarrer un autre lot.
5. Distinguer authoring workflow, UI premium, runtime et gameplay gaps.
6. Ne pas créer Selbrume final.
7. Ne pas créer Scene Builder complet ou Cinematic Builder complet.
8. Ne pas ouvrir rewards / money / XP hors demande explicite.
9. Fournir un Evidence Pack complet.
10. Mettre à jour cette roadmap vivante.
11. Ne modifier `road_map_global.md` qu'au checkpoint ou sur demande explicite.

## 7. Lots Phase 4 proposés

### P4-00 — Phase 4 Roadmap Bootstrap / Authoring Workflow Audit

Objectif :
Auditer l'existant côté editor/authoring, confirmer le découpage Phase 4 et
identifier les preuves nécessaires avant toute implémentation.

Résultat attendu :
Roadmap Phase 4 confirmée ou ajustée, risques authoring listés, prochain lot
P4-01 clarifié.

Non-objectifs :
Pas de widget UI, pas de Scene Builder, pas de Selbrume final, pas de gameplay
rewards.

### P4-01 — Narrative Reference Picker Coverage Review

Objectif :
Vérifier que les read models P2-10 couvrent les références nécessaires aux
workflows authoring minimaux, et lister les pickers encore manquants.

Résultat attendu :
Couverture Scenario / Outcome / Battle validée, gaps Story Step / Fact / World
Rule / Event Source classés.

### P4-02 — Scenario Authoring Minimal Workflow Design

Objectif :
Définir le workflow minimal pour authorer un `ScenarioAsset` sans exposer le
graphe technique comme expérience principale.

Résultat attendu :
Contrat de workflow et limites claires, sans créer Scene Builder complet.

### P4-03 — Event Source Authoring Minimal Workflow Design

Objectif :
Définir comment l'auteur choisit `mapEnter`, `triggerEnter`, `entityInteract` et
`outcomeReceived` à partir de sources lisibles.

Résultat attendu :
Workflow minimal source Event, diagnostics nécessaires, reports explicites.

### P4-04 — Outcome / Battle Outcome Authoring Minimal Workflow Design

Objectif :
Définir l'authoring minimal des outcomes scénario et battle outcomes sans
OutcomeRegistry ni BattleRegistry.

Résultat attendu :
Workflow lisible pour déclarer, émettre, recevoir et brancher les outcomes.

### P4-05 — Fact / Predicate / World Rule Authoring Minimal Workflow Design

Objectif :
Définir l'authoring minimal des facts techniques, predicates et world rules
passives sans FactRegistry ni WorldRuleRegistry.

Résultat attendu :
Workflow minimal de projection passive, limites avec GameState et reports.

### P4-06 — Narrative Validator Integration Readiness

Objectif :
Vérifier comment les diagnostics P2-09 peuvent être exposés dans les workflows
authoring minimaux sans créer d'auto-fix ou d'UI premium.

Résultat attendu :
Plan d'intégration validator, priorités de diagnostics, garde-fous.

### P4-07 — Minimal Authoring Golden Path Proposal

Objectif :
Proposer un golden path authoring minimal reliant pickers, scenario, sources,
outcomes, predicates et diagnostics.

Résultat attendu :
Proposition prête pour checkpoint, sans créer Selbrume final.

### P4-CHECKPOINT-01 — Authoring Workflow Readiness Review

Objectif :
Clôturer Phase 4, vérifier les preuves authoring minimales et décider le
passage vers la phase suivante.

Résultat attendu :
Verdict Phase 4, roadmaps mises à jour, prochain lot exact fixé.

## 8. Critères de sortie Phase 4

Phase 4 pourra être clôturée si :

- les workflows authoring minimaux sont définis ou prouvés ;
- les pickers/read models nécessaires sont couverts ou reportés clairement ;
- les diagnostics utilisables avant runtime sont intégrables ;
- les limites UI premium restent explicites ;
- aucun registry persistant prématuré n'est créé ;
- aucun contenu Selbrume final n'est créé ;
- les gaps gameplay restent reportés à Phase 5 ;
- la roadmap globale est mise à jour au checkpoint.

## 9. Décisions à valider avant ou pendant P4-00

- Confirmer cette roadmap Phase 4.
- Choisir le niveau de preuve authoring attendu.
- Définir si P4 reste design-first ou commence des prototypes purs ciblés.
- Confirmer que l'UI premium reste Phase 7.
- Confirmer que rewards / money / XP restent Phase 5.
- Confirmer que Selbrume final reste Phase 6.

## 10. Rappels permanents

```text
Phase 4 prépare l'authoring minimal.
Phase 4 ne crée pas UI premium.
Phase 4 ne crée pas Selbrume final.
Phase 4 ne crée pas de registry persistant.
Phase 4 n'ouvre pas rewards / money / XP.
```

Le prochain lot exact est :

```text
P4-00 — Phase 4 Roadmap Bootstrap / Authoring Workflow Audit
```
