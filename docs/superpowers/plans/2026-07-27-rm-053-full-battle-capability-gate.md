# RM-053 Full Battle Capability Gate Implementation Plan

**Goal:** promouvoir dans une gate combat complète les objets tenus, la
fidélité nature/IV/EV et Struggle, sans modifier la cutline MVP de `RM-026`.

**Architecture:** `BattleMvpCapabilityGate` reste la source bloquante
`battle.mvp.v0` avec dix capacités promues et trois extensions différées.
`BattleFullCapabilityGate` réutilise les dix preuves MVP et remplace uniquement
les trois extensions par leurs attestations complètes. Le générateur publie des
artefacts déterministes séparés pour les deux gates.

**Lots concernés:** `RM-053`, `FG-053`, `FG-183`.

## Task 1: Caractériser les deux cutlines

- [x] Prouver que la gate MVP conserve exactement 10 capacités bloquantes.
- [x] Prouver que la gate complète promeut exactement 13 capacités.
- [x] Prouver que la gate complète reste déclarée non bloquante pour FG-185.
- [x] Prouver le fail-closed si une extension complète perd une référence.

## Task 2: Attester les extensions

- [x] Relier l’authoring, le contrat, le runtime, la surface joueur et les
  preuves positive/négative des objets tenus.
- [x] Relier le contrat persisté, le calcul gameplay, le runtime et les preuves
  positive/négative nature/IV/EV.
- [x] Relier le contrôle joueur, la décision, l’adapter runtime, le menu et les
  preuves positive/négative Struggle.

## Task 3: Générer les artefacts

- [x] Ajouter les sorties JSON et Markdown `battle_full_capability_gate_v0`.
- [x] Étendre `--write` et `--check` sans modifier le contenu canonique MVP.
- [x] Vérifier la résolution de chaque `path#marker`.

## Task 4: Vérifier et clôturer

- [x] Exécuter le test ciblé et l’analyse `map_core`.
- [x] Exécuter les preuves ciblées dans battle, gameplay, runtime et editor.
- [x] Produire l’Evidence Pack avec les cinq passes nommées.
- [x] Vérifier le diff, isoler les sept fichiers utilisateur et committer RM-053.
