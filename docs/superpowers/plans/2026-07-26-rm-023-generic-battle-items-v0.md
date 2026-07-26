# RM-023 Generic Battle Items V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans and superpowers:test-driven-development.

**Goal:** Rendre utilisables en combat les medicines HP, cures de statut et
Revive via une décision PSDK générique, une cible de party explicite et une
consommation d'inventaire post-acceptation.

**Architecture:** `map_gameplay` reste le registre canonique des effets
d'items joueur. `map_battle` reçoit un effet résolu et l'applique à un index de
party explicite. `map_runtime` prévalide la cible, soumet la décision, exige un
événement `item_consumed`, puis seulement écrit le résultat et débite le bag.
L'overlay dérive ses cibles du type d'effet réel.

**Non-goals:** restauration de PP (`RM-041`), items tenus (`RM-024`), catalogue
de battle items auteuré par trainer.

---

### Task 1: Cible de party et Revive dans `map_battle`

- [x] Tests RED heal réserve, cure statut et revive.
- [x] Ajouter `targetPartyIndex` à la décision/action item.
- [x] Ajouter `PsdkBattleReviveItemEffect`.
- [x] Ajouter une mutation immuable cohérente party + slot actif.
- [x] Faire valider l'item par la façade canonique RM-022.

### Task 2: Transaction runtime générique

- [x] Tests RED sur antidote, full-heal, revive et rejet sans débit.
- [x] Résoudre l'effet depuis `PlayerItemEffectRegistry.mvp`.
- [x] Mapper statuts gameplay → PSDK.
- [x] Soumettre au moteur avant consommation.
- [x] Exiger l'événement consommé exact.
- [x] Écrire HP/statut sur les slots de party runtime puis consommer une unité.
- [x] Préserver le wrapper HP historique comme compatibilité.

### Task 3: UI de sélection honnête

- [x] Étendre le bag aux medicines heal/cure/revive supportées.
- [x] Rendre les cibles selon l'effet : blessé, statut compatible ou K.O.
- [x] Autoriser les réserves PSDK.
- [x] Ajouter les raisons désactivées no-code pertinentes.

### Task 4: Vérification

- [x] Tests/analyse `map_gameplay`, `map_battle`, `map_runtime`.
- [x] Suites complètes des packages modifiés.
- [x] Smoke Golden runtime.
- [x] Evidence Pack `FG-050`.
- [x] Commit isolé et état Git final.
