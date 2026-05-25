# Phase 6 Roadmap — Selbrume Golden Slice réel

## Statut de la phase

Phase 6 ouverte par le checkpoint Phase 5.

Statut : 🟡 active

SELBRUME_EXISTING_PROJECT_PATH :

```text
/Users/karim/Desktop/selbrume
```

Lot courant : ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Prochain lot exact : P6-01 — Existing Selbrume Loadability / Start Map Contract V0

Légende :

- ✅ terminé
- ➡️ prochain lot exact
- ⏳ à venir
- 🧭 checkpoint
- ⏭️ reporté

Phase 6 assemble un golden slice Selbrume jouable à partir des briques
techniques prouvées en Phase 5 et du projet Selbrume existant fourni par Karim.
Elle ne part pas de zéro et ne doit pas devenir une campagne complète, une UI
premium, un Boot Flow complet ou une quête de parité Pokémon.

Suivi des lots :

- ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
- ➡️ P6-01 — Existing Selbrume Loadability / Start Map Contract V0
- ⏳ P6-02 — Selbrume Initial Party / Bag Setup V0
- ⏳ P6-03 — Selbrume First Narrative Interaction V0
- ⏳ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
- ⏳ P6-05 — Selbrume First Trainer Battle Golden Slice V0
- ⏳ P6-06 — Selbrume Save/Load Golden Slice V0
- ⏳ P6-07 — Selbrume Beta Validator Pass V0
- ⏳ P6-08 — Selbrume Playable Runtime Smoke V0
- 🧭 P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

P6-00 : ✅ terminé

P6-01 : ➡️ prochain lot exact

Prochain lot exact :

```text
P6-01 — Existing Selbrume Loadability / Start Map Contract V0
```

## Objectif Phase 6

Auditer et réconcilier le projet Selbrume existant, déjà partiellement créé par
Karim, afin d'en extraire un premier golden slice court, jouable, validé et
sauvegardable.

La trajectoire attendue est :

```text
projet Selbrume existant
-> audit léger puis audit complet P6-00
-> choix d'un mini-parcours golden slice
-> alignement disque / données / runtime
-> maps et spawn Selbrume V0
-> New Game minimal
-> party initiale / bag minimal
-> première interaction narrative
-> trainer battle
-> rewards
-> save/load
-> validator bêta
-> runtime smoke
```

Le contenu Selbrume doit rester borné : une preuve jouable courte extraite du
projet existant, pas une campagne finale et pas une création from scratch.

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

## Décision P5-CHECKPOINT-01-bis

La Phase 6 part du projet Selbrume existant fourni par Karim :

```text
/Users/karim/Desktop/selbrume
```

P6-00 devra auditer ce projet existant, verrouiller un périmètre de golden
slice court, puis proposer les corrections ou alignements nécessaires. Cette
roadmap ne demande pas de recréer Selbrume from scratch.

## Résultat P6-00

Audit réalisé en lecture seule :

```text
project.json lisible
10 maps déclarées et présentes
30 tilesets déclarés et présents
1 dialogue Yarn présent mais placeholder
2 scénarios présents mais non branchés à une interaction exploitable
1 spawn player_start présent sur la map Selbrume
route 1 contient des zones de rencontre walk
1 table d'encounter existe avec pidgeotto
0 trainer déclaré
```

Golden slice candidat retenu :

```text
Départ : map Selbrume, spawn entity id "spawn", facing south
Étape 1 : première interaction narrative courte à créer / brancher
Étape 2 : transition Selbrume -> route 1 via connexion est/ouest
Étape 3 : rencontre route 1, puis trainer battle dès qu'un trainer minimal existe
Étape 4 : reward minimal
Étape 5 : save/load
Étape 6 : validator bêta
```

Gaps principaux :

```text
start map contract non explicite dans project.json
defaultSpawnId non renseigné malgré un spawn joueur existant
dialogue Yarn placeholder et non branché
aucun trainer déclaré
capture item / party / bag initial non authorés dans le projet Selbrume
validator bêta susceptible de signaler starter/initial party, trainer et capture source
```

## Roadmap

### ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Statut : terminé.

But :

```text
auditer le projet Selbrume existant fourni par Karim
vérifier quelles preuves Phase 5 peuvent être réutilisées telles quelles
choisir un mini-parcours golden slice à partir de l'état réel du projet
fixer les corrections / alignements nécessaires
```

Preuve attendue :

```text
rapport P6-00
inventaire du projet Selbrume existant
gaps de contenu classés
scope golden slice verrouillé
prochain lot exact confirmé ou ajusté
aucun lancement de production de contenu massif
```

### ➡️ P6-01 — Existing Selbrume Loadability / Start Map Contract V0

But :

```text
prouver ou corriger minimalement la charge du projet Selbrume existant et fixer
le contrat de start map / spawn sans créer de contenu final.
```

### ⏳ P6-02 — Selbrume Initial Party / Bag Setup V0

But :

```text
fournir une party initiale et un bag minimal utilisables dans le golden slice.
```

### ⏳ P6-03 — Selbrume First Narrative Interaction V0

But :

```text
prouver une première interaction narrative courte dans le mini-parcours choisi.
```

### ⏳ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0

But :

```text
prouver une rencontre route 1 bornée et une capture minimale si le bag initial
fournit une source de capture.
```

### ⏳ P6-05 — Selbrume First Trainer Battle Golden Slice V0

But :

```text
prouver un premier trainer battle Selbrume court avec reward minimal.
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
