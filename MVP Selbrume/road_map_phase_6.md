# Phase 6 Roadmap — Selbrume Golden Slice réel

## Statut de la phase

Phase 6 ouverte par le checkpoint Phase 5.

Statut : 🟡 active

Lot courant : ➡️ P6-00 — Phase 6 Roadmap Bootstrap / Selbrume Beta Content Audit

Prochain lot exact : P6-00 — Phase 6 Roadmap Bootstrap / Selbrume Beta Content Audit

Légende :

- ✅ terminé
- ➡️ prochain lot exact
- ⏳ à venir
- 🧭 checkpoint
- ⏭️ reporté

Phase 6 assemble un golden slice Selbrume jouable à partir des briques
techniques prouvées en Phase 5. Elle ne doit pas devenir une campagne complète,
une UI premium, un Boot Flow complet ou une quête de parité Pokémon.

Suivi des lots :

- ➡️ P6-00 — Phase 6 Roadmap Bootstrap / Selbrume Beta Content Audit
- ⏳ P6-01 — Selbrume Project Skeleton / Disk Layout V0
- ⏳ P6-02 — Selbrume Start Map / Spawn / New Game Wiring V0
- ⏳ P6-03 — Selbrume Starter / Initial Party / Bag Setup V0
- ⏳ P6-04 — Selbrume First Trainer Battle Golden Slice V0
- ⏳ P6-05 — Selbrume Capture Encounter Golden Slice V0
- ⏳ P6-06 — Selbrume Save/Load Golden Slice V0
- ⏳ P6-07 — Selbrume Beta Validator Pass V0
- ⏳ P6-08 — Selbrume Playable Runtime Smoke V0
- 🧭 P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

P6-00 : ➡️ prochain lot exact

Prochain lot exact :

```text
P6-00 — Phase 6 Roadmap Bootstrap / Selbrume Beta Content Audit
```

## Objectif Phase 6

Assembler un golden slice Selbrume jouable à partir des preuves Phase 5 :

```text
projet disque réel
-> maps et spawn Selbrume V0
-> New Game minimal
-> party initiale / bag minimal
-> trainer battle
-> rewards
-> capture
-> save/load
-> validator bêta
-> runtime smoke
```

Le contenu Selbrume doit rester borné : une preuve jouable courte, pas une
campagne finale.

## Préconditions héritées de Phase 5

- chemin projet disque -> runtime bundle -> `PlayableMapGame.onLoad` prouvé ;
- New Game minimal, spawn, position et facing prouvés ;
- party initiale / starter minimal prouvé sans UI ;
- bag, medicine et recover party prouvés par opérations pures ;
- rewards money et level-up direct minimal prouvés ;
- capture party-or-storage prouvée avec persistence ;
- save/load gameplay disque prouvé ;
- runtime smoke New Game -> battle -> reward -> save/load prouvé ;
- validator bêta V0 disponible.

## Non-objectifs Phase 6

- ne pas créer Selbrume final complet ;
- ne pas créer une UI premium ;
- ne pas créer le Boot Flow complet ;
- ne pas ajouter écran titre, slots de sauvegarde ou cinématique d'ouverture ;
- ne pas réouvrir XP persistée complète, moves learned, évolution ou parité
  Pokémon complète ;
- ne pas créer de système audio sauf décision dédiée ultérieure.

## Roadmap

### ➡️ P6-00 — Phase 6 Roadmap Bootstrap / Selbrume Beta Content Audit

Statut : prochain lot exact.

But :

```text
auditer le contenu et les fixtures Selbrume existants
vérifier quelles preuves Phase 5 peuvent être réutilisées telles quelles
fixer la roadmap Phase 6 détaillée si un ajustement est nécessaire
```

Preuve attendue :

```text
rapport P6-00
inventaire contenu Selbrume
gaps de contenu classés
prochain lot exact confirmé
aucun lancement de production de contenu massif
```

### ⏳ P6-01 — Selbrume Project Skeleton / Disk Layout V0

But :

```text
poser ou valider un projet disque Selbrume minimal avec layout runtime propre.
```

### ⏳ P6-02 — Selbrume Start Map / Spawn / New Game Wiring V0

But :

```text
brancher une map de départ Selbrume, un spawn et un New Game minimal.
```

### ⏳ P6-03 — Selbrume Starter / Initial Party / Bag Setup V0

But :

```text
fournir une party initiale et un bag minimal utilisables dans le golden slice.
```

### ⏳ P6-04 — Selbrume First Trainer Battle Golden Slice V0

But :

```text
prouver un premier trainer battle Selbrume court avec reward minimal.
```

### ⏳ P6-05 — Selbrume Capture Encounter Golden Slice V0

But :

```text
prouver une capture Selbrume bornée avec destination party-or-storage.
```

### ⏳ P6-06 — Selbrume Save/Load Golden Slice V0

But :

```text
prouver que l'état Selbrume golden slice survit à un vrai save/load disque.
```

### ⏳ P6-07 — Selbrume Beta Validator Pass V0

But :

```text
faire passer le projet Selbrume minimal dans le validator bêta.
```

### ⏳ P6-08 — Selbrume Playable Runtime Smoke V0

But :

```text
prouver un smoke runtime jouable court sur le projet Selbrume minimal.
```

### 🧭 P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

But :

```text
déterminer si le golden slice Selbrume minimal est prêt pour la phase suivante.
```

## Reports explicites

Report Phase 7 ou chantier UX dédié :

```text
Boot Flow complet
écran titre
écran de slots
Continue / Nouvelle partie complet
UI premium
menus finaux
```

Report post-golden-slice :

```text
campagne Selbrume complète
toutes les maps finales
tous les PNJ et dialogues finaux
parité Pokémon complète
audio runtime complet
```
