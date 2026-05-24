# Phase 1 Roadmap — Canonical Product Model / Narrative Studio Foundations

## 1. Statut de la phase

Phase 1 — Canonical Product Model / Narrative Studio Foundations

Statut : 🔜 En préparation

Lot courant : P1-04 — Storyline / Chapter / Story Step Structure

Prochain lot exact après P1-04 : P1-05 — Selbrume Reference Grammar Mapping

Suivi des lots :

- ✅ P1-00 — Phase 1 Roadmap Bootstrap
- ✅ P1-01 — Canonical Narrative Product Model V1
- ✅ P1-02 — Event / Scene / Cinematic Boundary Contract
- ✅ P1-03 — Fact & World Rule Product Grammar
- ✅ P1-04 — Storyline / Chapter / Story Step Structure
- 🔜 P1-05 — Selbrume Reference Grammar Mapping
- P1-06 — No-code Workflow Specification
- P1-07 — Phase 2 Domain Contract Proposal
- P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

P1-00 : ✅ terminé

P1-01 : ✅ terminé

P1-02 : ✅ terminé

P1-03 : ✅ terminé

P1-04 : ✅ terminé

P1-05 : 🔜 prochain lot exact

## 2. Objectif de la Phase 1

Stabiliser les concepts produit et les frontières du futur Narrative Studio :
Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue Yarn,
Fact, World Rule et Validator.

La Phase 1 doit produire une grammaire produit canonique avant toute création de
modèles `map_core`, avant toute refonte UI moderne, et avant toute génération de
contenu Selbrume.

## 3. Pourquoi cette phase existe

Le bloc NS-GS a prouvé beaucoup de mécaniques au niveau application,
mais il n’a pas encore figé le modèle produit canonique.
Avant de coder de nouveaux modèles ou de lancer une UI moderne,
il faut verrouiller le vocabulaire, les responsabilités et les frontières.

Cette phase évite de transformer les acquis mechanics-first en accumulation de
flags, de scènes et de conventions implicites. Elle prépare une base lisible pour
un outil no-code où le créateur pense en situations, événements, scènes,
conséquences et faits du monde.

## 4. Préconditions

- La roadmap globale par phases existe dans
  `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
- La roadmap globale vivante existe dans
  `MVP Selbrume/road_map_global.md`.
- Le bloc NS-GS-01 → NS-GS-18 est considéré comme terminé au niveau
  mechanics-first, principalement au Level 2 Application.
- Les limites Level 3 Flame et Level 4 projet disque restent documentées comme
  non entièrement prouvées.
- La décision utilisateur est intégrée : la refonte UI moderne / premium doit
  être une phase tardive, après stabilisation produit, domaine, runtime,
  validation et workflows no-code.
- Selbrume reste un scénario de référence, pas un contenu final à générer dans
  le repo par l’agent.

## 5. Périmètre

La Phase 1 couvre :

- la définition produit de Storyline, Chapter et Story Step ;
- la définition produit d’Event, Scene et Cinematic ;
- la place de Dialogue Yarn et des outcomes dans la progression ;
- la définition de Fact comme vérité lisible du monde ;
- la définition de World Rule comme projection passive du GameState ;
- la définition du Validator comme diagnostic statique ;
- le mapping de référence Selbrume sans création de contenu final ;
- la spécification des workflows no-code minimaux sans UI finale ;
- la proposition de lots Phase 2 pour transformer les décisions produit en
  contrats de domaine.

## 6. Non-objectifs stricts

- pas de code de production ;
- pas de modèles Freezed/JsonSerializable ;
- pas de build_runner ;
- pas de modification ProjectManifest ;
- pas de UI moderne ;
- pas de Scene Builder visuel ;
- pas de Cinematic Builder visuel ;
- pas de Reward Model ;
- pas de Quest Engine ;
- pas de création de contenu Selbrume ;
- pas de project.json Selbrume.

## 7. Concepts à figer

- Storyline
- Chapter
- Story Step
- Event
- Scene
- Cinematic
- Dialogue Yarn
- Fact
- World Rule
- Validator

## 8. Frontières non négociables

- Event = déclenche.
- Scene = orchestre.
- Cinematic = met en scène linéairement.
- Yarn = dialogue + outcomes.
- Fact = vérité lisible du monde.
- World Rule = projection passive du GameState.
- Battle = résout le combat.
- Validator = diagnostique.

Confusions interdites :

- Scene ≠ Cinematic
- Event ≠ Scene
- Yarn ≠ moteur principal de progression
- Fact ≠ flag technique exposé à l’utilisateur
- World Rule ≠ Event
- Battle ≠ progression narrative
- Side Quest ≠ système totalement séparé obligatoire au départ
- UI finale ≠ priorité immédiate

## 9. Roadmap détaillée Phase 1

### ✅ P1-00 — Phase 1 Roadmap Bootstrap

Objectif :
Créer `road_map_phase_1.md` et figer la gouvernance de la Phase 1.

Type :
Documentaire / roadmap.

Scope :
Créer la roadmap vivante de Phase 1, inscrire les lots, les non-objectifs, les
critères de sortie, le prochain lot exact et la règle permanente de maintenance.

Non-objectifs :
Ne pas démarrer P1-01, ne pas définir le modèle produit détaillé, ne pas modifier
de code, ne pas créer Selbrume, ne pas générer de `project.json`.

Livrable attendu :

- `MVP Selbrume/road_map_phase_1.md`
- `reports/roadmap/phase_1/p1_00_phase_1_roadmap_bootstrap.md`

Critères de validation :

- la roadmap Phase 1 existe ;
- tous les lots P1-00 à P1-CHECKPOINT-01 sont inscrits ;
- P1-00 est marqué terminé ;
- P1-01 est le prochain lot exact ;
- la règle permanente de maintenance est inscrite ;
- l’Evidence Pack P1-00 est complet.

### ✅ P1-01 — Canonical Narrative Product Model V1

Objectif :
Définir Storyline, Chapter, Story Step, Event, Scene, Cinematic,
Dialogue Yarn, Fact, World Rule et Validator.

Type :
Documentaire / modèle produit canonique.

Scope :
Produire une première définition canonique, lisible et non technique des concepts
du futur Narrative Studio, avec responsabilités, exemples génériques et limites.

Non-objectifs :
Ne pas créer de modèles `map_core`, ne pas modifier `ProjectManifest`, ne pas
implémenter d’UI, ne pas créer Selbrume, ne pas générer de fixtures finales.

Livrable attendu :

- `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`

Critères de validation :

- chaque concept est défini ;
- les frontières avec les autres concepts sont explicites ;
- les confusions interdites sont traitées ;
- le vocabulaire reste no-code et créateur-friendly ;
- les impacts Phase 2 sont listés sans implémentation.

### ✅ P1-02 — Event / Scene / Cinematic Boundary Contract

Objectif :
Figer les frontières Event déclenche / Scene orchestre / Cinematic linéaire.

Type :
Documentaire / contrat de frontières produit.

Scope :
Décrire les responsabilités exactes d’un Event, d’une Scene et d’une Cinematic,
leurs données minimales attendues, leurs interactions, et les erreurs de modèle
à éviter.

Non-objectifs :
Ne pas créer un Event model, ne pas créer un SceneGraph model, ne pas créer un
Cinematic Builder, ne pas modifier le runtime.

Livrable attendu :

- `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`

Critères de validation :

- Event, Scene et Cinematic ne se recouvrent pas ;
- les déclencheurs, orchestrations et mises en scène sont séparés ;
- la relation avec Yarn, Battle, Fact et World Rule est clarifiée ;
- les besoins Phase 2 sont bornés.

### ✅ P1-03 — Fact & World Rule Product Grammar

Objectif :
Définir Fact comme vérité lisible et World Rule comme projection passive.

Type :
Documentaire / grammaire produit.

Scope :
Décrire comment un créateur doit penser les faits du monde, les conditions et les
règles de projection sans être exposé à des flags techniques bruts.

Non-objectifs :
Ne pas créer de FactRegistry, ne pas créer de WorldRuleRegistry, ne pas modifier
le Narrative Validator, ne pas créer d’UI.

Livrable attendu :

- `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`

Critères de validation :

- Fact et World Rule sont définis séparément ;
- les patterns visibles / cachés / dialogue conditionnel sont couverts ;
- les erreurs World Rule ≠ Event et Fact ≠ flag technique sont traitées ;
- les besoins de validation future sont listés.

### ✅ P1-04 — Storyline / Chapter / Story Step Structure

Objectif :
Définir la structure Storyline / Chapter / Story Step et le statut des side quests.

Type :
Documentaire / structure narrative produit.

Scope :
Décrire comment représenter une histoire principale, des chapitres, des étapes,
des embranchements et des storylines optionnelles sans créer un Quest Engine
séparé par défaut.

Non-objectifs :
Ne pas créer de Quest Engine, ne pas créer de Quest Journal, ne pas créer de
modèles persistants, ne pas modifier les save data.

Livrable attendu :

- `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`

Critères de validation :

- Storyline, Chapter et Story Step ont des responsabilités distinctes ;
- les side quests sont positionnées honnêtement ;
- la progression principale et optionnelle sont séparables ;
- les besoins Phase 2 sont prêts à être transformés en contrats.

### 🔜 P1-05 — Selbrume Reference Grammar Mapping

Objectif :
Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.

Type :
Documentaire / mapping de référence.

Scope :
Utiliser Selbrume comme scénario de référence pour vérifier que la grammaire
Phase 1 couvre events, scènes, Yarn outcomes, cinématiques, combats, facts,
steps, world rules, side quest availability et validator.

Non-objectifs :
Ne pas créer Selbrume.
Ne pas générer de maps, PNJ, dialogues, trainers, battles ou project.json.

Livrable attendu :

- `reports/roadmap/phase_1/p1_05_selbrume_reference_grammar_mapping.md`

Critères de validation :

- le Golden Slice “Lysa au port” est mappé concept par concept ;
- aucun contenu final Selbrume n’est créé ;
- les gaps de grammaire sont listés ;
- les décisions à reporter en Phase 2 sont explicites.

### P1-06 — No-code Workflow Specification

Objectif :
Décrire les workflows auteur minimaux sans UI finale :
créer Event, Scene, Fact, World Rule, battle ref, Yarn outcome, validator flow.

Type :
Documentaire / workflow no-code.

Scope :
Décrire les parcours utilisateur minimaux nécessaires pour authorer les
mécaniques prouvées sans dépendre d’une UI premium : pickers, validations,
prévisualisations conceptuelles et diagnostics.

Non-objectifs :
Ne pas implémenter une UI, ne pas créer de widgets Flutter, ne pas définir un
design system, ne pas créer de Scene Builder visuel complet.

Livrable attendu :

- `reports/roadmap/phase_1/p1_06_no_code_workflow_specification.md`

Critères de validation :

- les workflows minimaux sont décrits de bout en bout ;
- les points où des pickers remplacent les IDs bruts sont identifiés ;
- le validator est placé dans le flux auteur ;
- les dépendances Phase 2 / Phase 4 sont séparées.

### P1-07 — Phase 2 Domain Contract Proposal

Objectif :
Transformer les décisions Phase 1 en proposition de lots Phase 2.
Lister les modèles map_core à créer, adapter ou reporter.

Type :
Documentaire / proposition de contrats domaine.

Scope :
Préparer la transition vers Phase 2 en listant les contrats, modèles, diagnostics
et migrations potentielles à envisager, sans écrire de code.

Non-objectifs :
Ne pas modifier `map_core`, ne pas modifier les schemas JSON, ne pas lancer
`build_runner`, ne pas créer de modèles Freezed.

Livrable attendu :

- `reports/roadmap/phase_1/p1_07_phase_2_domain_contract_proposal.md`

Critères de validation :

- les décisions Phase 1 sont traduites en besoins domaine ;
- les lots Phase 2 proposés sont bornés ;
- les risques de migration sont listés ;
- les modèles à reporter sont explicitement justifiés.

### P1-CHECKPOINT-01 — Canonical Product Model Closure & Phase 2 Decision

Objectif :
Vérifier que Phase 1 a fermé les ambiguïtés et recommander la roadmap détaillée
Phase 2.

Type :
Checkpoint / décision de phase.

Scope :
Auditer tous les livrables Phase 1, distinguer ce qui est figé, partiel ou
reporté, et recommander la suite exacte.

Non-objectifs :
Ne pas démarrer Phase 2, ne pas implémenter les contrats, ne pas créer d’UI, ne
pas créer Selbrume.

Livrable attendu :

- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`

Critères de validation :

- chaque lot Phase 1 est évalué ;
- les ambiguïtés restantes sont listées ;
- la roadmap Phase 2 détaillée est recommandée ;
- le prochain lot exact de Phase 2 est clair ;
- aucun contenu final Selbrume n’est créé.

## 10. Prochain lot exact

P1-05 — Selbrume Reference Grammar Mapping

Objectif du prochain lot :
Mapper le Golden Slice Selbrume “Lysa au port” sur la grammaire canonique.

P1-05 ne doit pas créer de code, de modèles `map_core`, d’UI, de fixtures
Selbrume finales ou de `project.json`.

## 11. Critères de sortie de Phase 1

La Phase 1 pourra être fermée uniquement si :

- les concepts Storyline, Chapter, Story Step, Event, Scene, Cinematic, Dialogue
  Yarn, Fact, World Rule et Validator sont définis ;
- les frontières Event / Scene / Cinematic sont non ambiguës ;
- Fact et World Rule sont formulés en langage produit, pas en jargon de flags ;
- la structure Storyline / Chapter / Story Step couvre histoire principale et
  storylines optionnelles ;
- le Golden Slice Selbrume de référence est mappé sans générer de contenu final ;
- les workflows no-code minimaux sont décrits ;
- les besoins Phase 2 sont transformés en proposition de contrats domaine ;
- les non-objectifs Phase 1 sont respectés ;
- P1-CHECKPOINT-01 recommande explicitement la suite.

## 12. Règle permanente de maintenance de cette roadmap

À chaque lot de Phase 1, l’agent doit :

1. Lire `MVP Selbrume/road_map_phase_1.md` avant toute modification.
2. Lire `MVP Selbrume/road_map_global.md`.
3. Lire `reports/roadmap/pokemap_full_product_phased_roadmap_v1.md`.
4. Respecter le lot courant et le prochain lot exact.
5. Ne jamais démarrer un autre lot que celui demandé.
6. Mettre à jour le statut du lot exécuté.
7. Ajouter un résumé court du résultat.
8. Ajouter les fichiers créés ou modifiés.
9. Ajouter les commandes exécutées si applicable.
10. Ajouter les décisions utilisateur nouvelles.
11. Ajouter les changements de périmètre.
12. Mettre à jour la section “Prochain lot exact”.
13. Conserver un Evidence Pack dans le rapport du lot.
14. Ne jamais créer de contenu Selbrume final.
15. Ne jamais créer de project.json Selbrume.
16. Ne jamais implémenter de code pendant Phase 1 sauf demande explicite.

P1-CHECKPOINT-01 devra aussi mettre à jour
`MVP Selbrume/road_map_global.md` avant toute transition vers la Phase 2.

## 13. Décisions utilisateur intégrées

- La partie UI moderne / belle / refonte visuelle doit être l’une des dernières
  grandes phases.
- P1-00 crée uniquement la roadmap vivante de Phase 1.
- P1-01 ne démarre pas pendant P1-00.
- Selbrume sert de scénario de référence et ne doit pas être généré dans le repo.
- Phase 1 est documentaire et produit : elle fige les concepts avant les contrats
  `map_core` et avant l’UI moderne.

## 14. Gaps et sujets reportés

- Modèles `map_core` Storyline / Chapter / Story Step / Event : reportés à la
  Phase 2 si validés par la Phase 1.
- FactRegistry et WorldRuleRegistry : reportés à la Phase 2.
- Validation Flame Level 3 et projet disque Level 4 : reportés à une phase de
  validation runtime / disk.
- Reward Model, money, XP et level-up : reportés à une sous-roadmap gameplay
  future.
- UI moderne, App Shell, Scene Builder visuel, Cinematic Builder visuel et
  Validator UI : reportés à une phase UI tardive.
- Selbrume Golden Slice réel créé dans l’éditeur : reporté à une phase dédiée
  après stabilisation produit, domaine, runtime et authoring.

## 15. Historique des mises à jour de Phase 1

- 2026-05-24 — P1-00 — Roadmap Phase 1 créée. P1-00 marqué terminé. Prochain
  lot exact fixé à P1-01 — Canonical Narrative Product Model V1.
- 2026-05-24 — P1-01 — Canonical Narrative Product Model V1 terminé.
  Résultat : définition canonique produit de Storyline, Chapter, Story Step,
  Event, Scene, Cinematic, Dialogue Yarn, Fact, World Rule et Validator.
  Fichiers créés : `reports/roadmap/phase_1/p1_01_canonical_narrative_product_model_v1.md`.
  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
  Commandes exécutées : lectures Markdown ciblées, `find`, `git status --short --untracked-files=all`,
  `git diff --check`, `git diff --stat`, `git diff --name-only`.
  Décisions utilisateur nouvelles : aucune.
  Changements de périmètre : aucun.
  Prochain lot exact fixé à P1-02 — Event / Scene / Cinematic Boundary Contract.
- 2026-05-24 — P1-02 — Event / Scene / Cinematic Boundary Contract terminé.
  Résultat : contrat produit strict Event déclenche / Scene orchestre /
  Cinematic met en scène linéairement, avec matrice de responsabilité et
  relations clarifiées avec Yarn, Battle, Fact, Story Step, World Rule et
  Validator.
  Fichiers créés : `reports/roadmap/phase_1/p1_02_event_scene_cinematic_boundary_contract.md`.
  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
  Commandes exécutées : lectures Markdown ciblées, `find`, `git status --short --untracked-files=all`,
  `git diff --check`, `git diff --stat`, `git diff --name-only`,
  `git diff --no-index --check`, `wc -l`.
  Décisions utilisateur nouvelles : aucune.
  Changements de périmètre : aucun.
  Prochain lot exact fixé à P1-03 — Fact & World Rule Product Grammar.
- 2026-05-24 — P1-03 — Fact & World Rule Product Grammar terminé.
  Résultat : grammaire produit stricte Fact = vérité lisible / World Rule =
  projection passive, avec nommage no-code, cycle de vie des facts, types de
  projections visibles et mapping prudent vers l’existant.
  Fichiers créés : `reports/roadmap/phase_1/p1_03_fact_world_rule_product_grammar.md`.
  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
  Commandes exécutées : lectures Markdown ciblées,
  `git status --short --untracked-files=all`, `git diff --check`,
  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`,
  `wc -l`.
  Décisions utilisateur nouvelles : aucune.
  Changements de périmètre : aucun.
  Prochain lot exact fixé à P1-04 — Storyline / Chapter / Story Step Structure.
- 2026-05-24 — P1-04 — Storyline / Chapter / Story Step Structure terminé.
  Résultat : structure narrative produit stricte Storyline = ligne narrative /
  Chapter = section / Story Step = jalon, avec side quest positionnée comme
  Storyline secondaire sans Quest Engine ni Quest Journal.
  Fichiers créés : `reports/roadmap/phase_1/p1_04_storyline_chapter_story_step_structure.md`.
  Fichiers modifiés : `MVP Selbrume/road_map_phase_1.md`.
  Commandes exécutées : lectures Markdown ciblées, `rg`, `wc -l`,
  `git status --short --untracked-files=all`, `git diff --check`,
  `git diff --stat`, `git diff --name-only`, `git diff --no-index --check`.
  Décisions utilisateur nouvelles : aucune.
  Changements de périmètre : aucun.
  Prochain lot exact fixé à P1-05 — Selbrume Reference Grammar Mapping.
