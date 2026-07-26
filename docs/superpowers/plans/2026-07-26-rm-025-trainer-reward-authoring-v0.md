# RM-025 Trainer Reward Authoring V0 Implementation Plan

**Goal:** permettre d’authorer sans JSON les récompenses d’un dresseur :
argent, objets, flags, badge optionnel et capacité de terrain, puis garantir que
le runtime projette exactement ces données dans la transaction post-combat.

**Architecture:** `map_core` reste la source de vérité sérialisée ;
`map_editor` normalise et valide un draft guidé ; `map_runtime` ne déduit rien
et projette les champs vers le `BattleReward` pur de `map_gameplay`.

**Non-goals:** inventaire d’objets utilisables par l’IA, économie dynamique,
récompenses aléatoires, scripts arbitraires post-combat et templates trainer
(réservés à RM-027).

### Task 1: Contrat core

- [x] Ajouter badge et field unlock optionnels au trainer.
- [x] Préserver les defaults legacy et le round-trip JSON.
- [x] Valider argent, grants, flags, badge et field unlock.

### Task 2: Use cases et runtime

- [x] Normaliser création/édition des récompenses.
- [x] Préserver les champs quand ils sont omis et permettre leur effacement.
- [x] Projeter badge et field unlock vers `BattleReward`.
- [x] Prouver l’application différée et atomique existante.

### Task 3: Authoring no-code

- [x] Ajouter une section Récompenses au Trainer Studio.
- [x] Utiliser les primitives du design system.
- [x] Picker catalogue pour les objets.
- [x] Picker manifeste pour le badge.
- [x] Picker enum lisible pour la capacité de terrain.
- [x] Contrôle explicite argent, quantité et flags sans JSON.

### Task 4: Validation et clôture

- [x] Tests core, use cases, widget et runtime ciblés.
- [x] Suites/analyzes des packages modifiés.
- [x] Smokes Golden battle/runtime host.
- [x] Evidence Pack FG-051 / FG-143.
- [x] Commit isolé et état Git final.
