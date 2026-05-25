# Phase 5 Roadmap — Gameplay Gaps Prioritaires

## 1. Statut de la phase

Phase 5 — Gameplay Gaps Prioritaires

Statut : 🔜 Phase courante en préparation

Lot courant : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Prochain lot exact : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Suivi des lots :

- 🔜 P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
- P5-01 — New Game / Initial GameState Contract Review
- P5-02 — Starter / Initial Party Minimal Flow
- P5-03 — Runtime Party Menu Minimal Read Model
- P5-04 — Bag / Item Use Runtime Minimal Contract
- P5-05 — Heal Center Minimal Flow
- P5-06 — Battle Rewards / Money / XP Minimal Contract
- P5-07 — Capture Destination / Party-or-Box Decision
- P5-08 — Gameplay Save/Load Beta Roundtrip
- P5-09 — Beta Playability Validator Plan
- P5-CHECKPOINT-01 — Gameplay Loop Readiness Review

P5-00 : 🔜 prochain lot exact

## 2. Objectif de la Phase 5

Fermer la boucle RPG minimale nécessaire à une bêta jouable : New Game, état
initial, party, bag, combat, capture, rewards, XP, heal center, save/load
runtime et validation de jouabilité.

La Phase 5 doit répondre à la question :

```text
PokeMap possède-t-il une boucle RPG courte et générique suffisamment prouvée
pour soutenir une bêta jouable, sans viser la parité Pokémon complète ?
```

## 3. Pourquoi cette phase existe

Les Phases 1 à 4 ont stabilisé la grammaire produit, les contrats domaine, le
runtime/disk narratif et l'authoring minimal pur. Il reste à traiter les gaps
gameplay qui empêchent une expérience fangame courte de se tenir :

- démarrage de partie ;
- état initial joueur ;
- party ;
- bag/items ;
- heal center ;
- rewards / money / XP ;
- capture et destination party/box ;
- save/load gameplay ;
- validation de jouabilité bêta.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- Phase 2 clôturée avec réserves mineures.
- Phase 3 clôturée avec réserves mineures.
- Phase 4 clôturée avec réserves mineures.
- `reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 5.
- `pokemap_roadmap_mecaniques_fangame.md` reste la source de contexte
  mechanics-first pour les gaps RPG.

## 5. Périmètre Phase 5

Inclus :

- audit gameplay / RPG loop minimal ;
- New Game et GameState initial ;
- party/starter flow minimal ;
- read model runtime party menu minimal ;
- bag / item use runtime contract minimal ;
- heal center minimal ;
- battle rewards / money / XP minimal contract ;
- capture destination party-or-box ;
- save/load gameplay beta roundtrip ;
- plan validator de jouabilité bêta ;
- checkpoint Phase 5.

Exclus :

- UI premium ;
- Selbrume final complet ;
- contenu final de campagne ;
- post-game ;
- systèmes Pokémon complets ;
- parité Pokémon officielle ;
- refonte editor Phase 7 ;
- Scene Builder / Cinematic Builder ;
- génération automatique de jeu.

## 6. Règles de maintenance

À chaque lot Phase 5, l'agent doit :

1. Lire `AGENTS.md`.
2. Lire `MVP Selbrume/road_map_global.md`.
3. Lire `MVP Selbrume/road_map_phase_5.md`.
4. Lire `pokemap_roadmap_mecaniques_fangame.md`.
5. Identifier les lots/gaps mechanics-first concernés.
6. Respecter le prochain lot exact.
7. Ne pas démarrer un autre lot.
8. Distinguer audit, contrat, runtime, UI et contenu final.
9. Ne pas créer Selbrume final.
10. Ne pas viser la parité Pokémon complète.
11. Fournir un Evidence Pack complet.
12. Mettre à jour cette roadmap vivante.
13. Ne modifier `road_map_global.md` qu'au checkpoint ou sur demande explicite.

## 7. Lots Phase 5 proposés

### 🔜 P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit

Objectif :
Auditer l'existant gameplay, relier les gaps Phase 5 aux preuves NS-GS et aux
packages actuels, puis recalibrer la roadmap Phase 5 si nécessaire.

Résultat attendu :
Roadmap Phase 5 confirmée ou corrigée, priorités mechanics-first classées,
prochain lot P5-01 clarifié.

Non-objectifs :
Pas d'implémentation rewards/money/XP, pas de UI premium, pas de Selbrume final,
pas de refonte runtime large.

### P5-01 — New Game / Initial GameState Contract Review

Objectif :
Stabiliser le contrat minimal de démarrage de partie et l'état initial
nécessaire à une boucle RPG courte.

Résultat attendu :
Audit et, si le lot le permet, preuve ciblée du GameState initial sans migration
opportuniste.

### P5-02 — Starter / Initial Party Minimal Flow

Objectif :
Prouver un flux minimal pour obtenir une première créature / party initiale.

Résultat attendu :
Contrat ou opération pure testée permettant de poser une party initiale bornée.

### P5-03 — Runtime Party Menu Minimal Read Model

Objectif :
Fournir une vue minimale de la party exploitable par un runtime/menu futur sans
UI premium.

Résultat attendu :
Read model pur ou adapter ciblé, testé, sans refonte de menu complète.

### P5-04 — Bag / Item Use Runtime Minimal Contract

Objectif :
Clarifier le contrat minimal bag/items et l'usage d'item runtime nécessaire à la
bêta.

Résultat attendu :
Décision ou preuve pure bornée, sans shop complet ni inventory UI premium.

### P5-05 — Heal Center Minimal Flow

Objectif :
Prouver le flux minimal de soin party/état joueur nécessaire à la boucle RPG.

Résultat attendu :
Opération ou use case testable, sans contenu Selbrume ni UI finale.

### P5-06 — Battle Rewards / Money / XP Minimal Contract

Objectif :
Cadrer puis prouver le contrat minimal de sortie de combat : rewards, money, XP
et limites level-up.

Résultat attendu :
Preuve bornée ou micro-roadmap si le gap exige une décomposition, sans reward
engine massif.

### P5-07 — Capture Destination / Party-or-Box Decision

Objectif :
Décider et prouver le comportement minimal de capture quand la party est pleine
ou non.

Résultat attendu :
Opération/test minimal party-or-box, sans PC complet si le scope doit rester
borné.

### P5-08 — Gameplay Save/Load Beta Roundtrip

Objectif :
Valider que les états gameplay minimaux de Phase 5 survivent à un roundtrip
save/load réel ou documenter le gap.

Résultat attendu :
Preuve ciblée de persistence gameplay, distincte des preuves narratives Phase 3.

### P5-09 — Beta Playability Validator Plan

Objectif :
Définir les diagnostics de jouabilité nécessaires avant une bêta : party,
encounters, heal, save, rewards et chemins bloquants.

Résultat attendu :
Plan validator ou adapter minimal selon l'état du code, sans Validator UI.

### P5-CHECKPOINT-01 — Gameplay Loop Readiness Review

Objectif :
Clôturer Phase 5, vérifier les preuves gameplay minimales et décider le passage
vers la phase suivante.

Résultat attendu :
Verdict Phase 5, roadmaps mises à jour, prochain lot exact fixé.

## 8. Critères de sortie Phase 5

Phase 5 pourra être clôturée si :

- la boucle New Game -> party -> bag/heal -> battle -> rewards/progression ->
  capture -> save/load est prouvée ou ses gaps résiduels sont classés ;
- rewards / money / XP ne sont plus confondus avec facts/steps narratifs ;
- les preuves restent mechanics-first et testées ;
- les limites UI premium restent explicites ;
- Selbrume final reste reporté à Phase 6 ;
- la roadmap globale est mise à jour au checkpoint.

## 9. Rappels permanents

```text
Phase 5 traite les gaps gameplay prioritaires.
Phase 5 ne crée pas UI premium.
Phase 5 ne crée pas Selbrume final complet.
Phase 5 ne vise pas la parité Pokémon officielle.
Phase 5 doit rester mechanics-first et testée.
P5-00 est un audit : il ne doit pas implémenter P5-01 à P5-09.
```

Le prochain lot exact est :

```text
P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
```
