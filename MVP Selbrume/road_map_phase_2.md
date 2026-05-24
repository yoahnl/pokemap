# Phase 2 Roadmap — Domain Model & Contracts

## 1. Statut de la phase

Phase 2 — Domain Model & Contracts

Statut : 🔜 Prête à démarrer

Lot courant : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Prochain lot exact : P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Suivi des lots :

- 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
- P2-01 — Existing Narrative Domain Inventory
- P2-02 — Story Step Descriptor / Storyline Metadata Decision
- P2-03 — Event Authoring Source Contract
- P2-04 — Scene / ScenarioAsset Adapter Contract
- P2-05 — Outcome Reference Contracts
- P2-06 — Battle Reference / Outcome Contract
- P2-07 — Fact Descriptor / Presentation Layer
- P2-08 — World Rule Predicate Adapter Contract
- P2-09 — Narrative Validator Diagnostic Expansion
- P2-10 — Reference Picker Read Models
- P2-CHECKPOINT-01 — Domain Contracts Readiness Review

P2-00 : 🔜 prochain lot exact

## 2. Objectif de la Phase 2

Transformer la grammaire produit Phase 1 en socle domaine minimal, testable et
utilisable par les phases suivantes.

La Phase 2 doit construire ou stabiliser seulement les contrats qui ont des
consumers explicites :

- `map_core` diagnostics / contracts / read models ;
- `map_gameplay` condition et GameState si nécessaire ;
- `map_runtime` adapters d’exécution plus tard ;
- `map_editor` authoring workflows et picker sources plus tard ;
- save/load et project disk si un besoin persistant est prouvé.

Règle centrale :

```text
Pas de modèle sans consumer clair.
Pas de registry sans usage clair.
Pas de JSON/migration si le besoin n’est pas justifié.
```

## 3. Pourquoi cette phase existe

La Phase 1 a fermé la grammaire produit :

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

La Phase 2 doit maintenant vérifier comment cette grammaire se raccorde aux
structures existantes : `ScenarioAsset`, metadata editor, `completedStepIds`,
`storyFlags`, predicates runtime, `ProjectManifest`, `NarrativeValidator` et
sources de picker futures.

## 4. Préconditions

- Phase 1 clôturée avec réserves mineures.
- `reports/roadmap/phase_1/p1_checkpoint_01_canonical_product_model_closure.md`
  existe.
- `MVP Selbrume/road_map_global.md` pointe vers la Phase 2.
- Selbrume reste une référence conceptuelle.

## 5. Périmètre Phase 2

Inclus :

- audit de l’existant narratif ;
- décisions descriptor / adapter / contrat / report ;
- contrats domaine pure Dart si nécessaires ;
- diagnostics Validator prioritaires ;
- read models et sources de picker sans UI ;
- stratégie persistence / JSON / migration ;
- package boundaries.

Exclus :

- UI moderne ou premium ;
- Scene Builder complet ;
- Cinematic Builder complet ;
- runtime Flame Golden Slice ;
- projet disque Selbrume ;
- contenu Selbrume final ;
- Reward Model unifié ;
- Quest Engine ;
- Quest Journal ;
- money / XP / level-up ;
- static wild authoring complet ;
- Door/Warp Engine complet.

## 6. Non-objectifs stricts

- Ne pas créer Selbrume final.
- Ne pas créer de `project.json` Selbrume.
- Ne pas lancer Phase 3 runtime/disk.
- Ne pas lancer Phase 4 authoring UI.
- Ne pas lancer Phase 7 UI premium.
- Ne pas coupler `map_battle` au Narrative Studio.
- Ne pas faire de `map_editor` la source de vérité domaine.
- Ne pas modifier `ProjectManifest` sans décision explicite et migration
  documentée.

## 7. Lots Phase 2 proposés

### 🔜 P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit

Objectif :
Vérifier le découpage Phase 2, auditer précisément les structures existantes et
confirmer les premiers lots de contrats.

Fichiers probables à auditer :

- `reports/roadmap/phase_1/*`
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_2.md`
- `packages/map_core/lib/src/models/*`
- `packages/map_core/lib/src/operations/narrative_validator.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/*`
- `packages/map_editor/lib/src/features/narrative/*`

Risque :
Créer trop tôt des modèles au lieu de caractériser l’existant.

Tests probables :
Pas de test obligatoire si le lot reste audit/documentaire. Si un audit outillé
est ajouté, il doit rester borné et justifié.

Non-objectifs :
Pas de contrat codé, pas de modèle `map_core`, pas de JSON, pas de migration,
pas de Selbrume final.

Dépendances :
P1-CHECKPOINT-01.

### P2-01 — Existing Narrative Domain Inventory

Objectif :
Inventorier `ScenarioAsset`, metadata narrative, validators, runtime source
events, predicates, save state et authoring projections.

Risque :
Sous-estimer les conventions déjà présentes dans metadata editor.

Tests probables :
Caractérisation si des read models d’inventaire sont créés.

Non-objectifs :
Pas de nouveau modèle persistant.

Dépendances :
P2-00.

### P2-02 — Story Step Descriptor / Storyline Metadata Decision

Objectif :
Décider si Storyline / Chapter / Story Step démarrent comme descriptors,
metadata légère, adapter, ou report partiel.

Risque :
Dupliquer `completedStepIds` ou transformer Story Step en flag technique brut.

Tests probables :
Diagnostics pure Dart sur steps inconnus, orphelins ou jamais complétés si un
contrat est créé.

Non-objectifs :
Pas de Quest Engine, pas de Quest Journal.

Dépendances :
P2-01.

### P2-03 — Event Authoring Source Contract

Objectif :
Formaliser les sources auteur d’Event sans dupliquer inutilement les runtime
source events.

Risque :
Transformer Event en mini-Scene.

Tests probables :
Validation de références source / target si contrat créé.

Non-objectifs :
Pas de runtime Flame.

Dépendances :
P2-01.

### P2-04 — Scene / ScenarioAsset Adapter Contract

Objectif :
Décider si Scene est le nom produit de `ScenarioAsset`, un wrapper, ou un
adapter/read model.

Risque :
Casser `ScenarioAsset` ou créer un modèle parallèle inutile.

Tests probables :
Adapter/read model et diagnostics de nodes/outcomes si contrat créé.

Non-objectifs :
Pas de Scene Builder complet.

Dépendances :
P2-01.

### P2-05 — Outcome Reference Contracts

Objectif :
Rendre les outcomes Yarn / Scenario sélectionnables et validables sans exposer
`scenario.outcome.*` comme UX principale.

Risque :
Créer un OutcomeRegistry trop tôt.

Tests probables :
Outcomes déclarés / émis / consommés / orphelins.

Non-objectifs :
Pas de parser Yarn complet.

Dépendances :
P2-04.

### P2-06 — Battle Reference / Outcome Contract

Objectif :
Stabiliser un contrat minimal de référence battle et outcomes `victory` /
`defeat`.

Risque :
Aspirer money, XP, static wild et rewards dans Phase 2.

Tests probables :
Référence trainer/battle absente, outcome non géré, branch post-battle absente.

Non-objectifs :
Pas de static wild complet, pas de money/XP, pas de Reward Model unifié.

Dépendances :
P2-04.

### P2-07 — Fact Descriptor / Presentation Layer

Objectif :
Fournir des labels humains et relations de source/consumer pour les vérités du
monde, sans dupliquer le GameState.

Risque :
Créer un FactRegistry lourd ou exposer des flags bruts avec un label cosmétique.

Tests probables :
Fact inconnu, jamais écrit, jamais lu, technique sans label humain.

Non-objectifs :
Pas de duplication automatique de state.

Dépendances :
P2-02, P2-05.

### P2-08 — World Rule Predicate Adapter Contract

Objectif :
Adapter les predicates et projections conditionnelles existantes à la grammaire
World Rule.

Risque :
Créer un WorldRuleRegistry prématuré ou laisser World Rule déclencher des
Scenes.

Tests probables :
Condition absente, target absent, conflit de rules, rule utilisée comme Event.

Non-objectifs :
Pas de World Rule qui écrit des Facts ou complète des Steps.

Dépendances :
P2-07.

### P2-09 — Narrative Validator Diagnostic Expansion

Objectif :
Étendre les diagnostics narratifs prioritaires par domaine : Story Step, Event,
Scene, outcomes, Battle, Fact, World Rule et side quest.

Risque :
Produire trop de diagnostics non actionnables.

Tests probables :
Tests unitaires ciblés par diagnostic.

Non-objectifs :
Pas d’auto-correction.

Dépendances :
P2-02 à P2-08.

### P2-10 — Reference Picker Read Models

Objectif :
Préparer les sources pures de pickers Phase 4 sans créer de widgets UI.

Risque :
Confondre read model et widget Flutter.

Tests probables :
Tri stable, labels humains, références cassées, listes filtrées.

Non-objectifs :
Pas d’UI Flutter, pas de design system.

Dépendances :
P2-09.

### P2-CHECKPOINT-01 — Domain Contracts Readiness Review

Objectif :
Clôturer Phase 2, vérifier les contrats créés/adaptés/reportés, les diagnostics
et les package boundaries.

Risque :
Clôturer avec des migrations ou duplications d’état cachées.

Tests probables :
Commandes ciblées selon les packages réellement modifiés en Phase 2.

Non-objectifs :
Pas de Phase 3 démarrée.

Dépendances :
P2-10.

## 8. Critères de sortie Phase 2

Phase 2 pourra être clôturée si :

- les contrats domaine nécessaires au Narrative Studio sont créés, adaptés ou
  explicitement reportés ;
- les diagnostics essentiels sont présents ou reportés avec justification ;
- les pickers Phase 4 disposent de sources de données propres ;
- les package boundaries restent respectées ;
- tout modèle persistant a une justification claire ;
- aucune migration `ProjectManifest` inutile n’est introduite ;
- aucun contenu Selbrume final n’est créé ;
- Phase 3 peut valider runtime/disk sur une base stable.

## 9. Règle permanente de maintenance

À chaque lot Phase 2, l’agent doit :

1. Lire `MVP Selbrume/road_map_global.md`.
2. Lire `MVP Selbrume/road_map_phase_2.md`.
3. Lire les rapports Phase 1 pertinents.
4. Respecter le prochain lot exact.
5. Ne pas démarrer un autre lot.
6. Distinguer création, adaptation et report.
7. Justifier chaque nouveau contrat par des consumers explicites.
8. Fournir un Evidence Pack complet.
9. Mettre à jour cette roadmap vivante.
10. Ne modifier `road_map_global.md` qu’au checkpoint ou sur demande explicite.

## 10. Décisions à valider avant ou pendant P2-00

- Valider la roadmap Phase 2 proposée.
- Confirmer audit-first avant création directe de contrats.
- Décider si Scene est `ScenarioAsset`, wrapper ou adapter/read model.
- Décider FactDescriptor / Fact Presentation Layer avant FactRegistry.
- Décider World Rule Predicate Adapter avant WorldRuleRegistry.
- Décider si Storyline / Chapter deviennent persistants dès Phase 2.
- Confirmer que rewards, Quest Journal et UI premium restent reportés.

## 11. Rappels permanents

```text
Phase 2 construit les contrats utiles.
Phase 2 ne construit pas Selbrume.
Phase 2 ne construit pas l’UI premium.
Phase 2 ne prouve pas le runtime Flame complet.
```

Le prochain lot exact est :

```text
P2-00 — Phase 2 Roadmap Bootstrap / Domain Contract Audit
```
