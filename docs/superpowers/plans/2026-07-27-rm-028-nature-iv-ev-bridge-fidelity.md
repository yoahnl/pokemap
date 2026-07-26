# RM-028 Nature/IV/EV Bridge Fidelity Implementation Plan

**Goal:** appliquer la nature et les IV/EV persistés aux stats battle runtime,
et remplacer les valeurs adverses implicites par deux profils V0 déterministes.

**Architecture:** `map_gameplay` devient l’unique propriétaire de la formule de
stats et du catalogue canonique des 25 natures. `map_runtime` charge les données
projet puis appelle ce calculateur pour les seeds legacy et PSDK. Les profils
adverses restent des règles gameplay pures, sans ajouter de faux authoring
avancé dans `map_core` ou `map_editor`.

**Opponent policy V0:**

- sauvage : nature Hardy, IV 0, EV 0 ;
- trainer/statique : nature Hardy, IV 15 partout, EV 0.

**Non-goals:** UI d’édition IV/EV/nature (`FG-206`), génération aléatoire des
IV/natures sauvages, EV gagnés en combat, migration de sauvegarde, RM-053.

### Task 1: Contrat gameplay canonique

- [x] Ajouter les 25 natures et leurs modifiers 110/90.
- [x] Appliquer le modifier après le floor de la stat non-HP.
- [x] Rejeter une nature canonique absente au lieu de neutraliser silencieusement.
- [x] Définir les profils adverses sauvage et trainer V0.

### Task 2: Bridge runtime unique

- [x] Remplacer les formules runtime dupliquées par `PokemonStatCalculator`.
- [x] Appliquer nature/IV/EV joueur aux seeds legacy et PSDK.
- [x] Appliquer les profils adverses aux wild/trainer/static seeds.
- [x] Garder un diagnostic clair pour une nature ou spread invalide.

### Task 3: Cohérence des autres consommateurs

- [x] Utiliser la nature persistée dans progression et évolution.
- [x] Utiliser la nature persistée dans les caps HP runtime.
- [x] Préserver HP courant, PP, objet tenu et metadata existants.

### Task 4: Validation et clôture

- [x] Tests gameplay et runtime positifs/négatifs.
- [x] Suites package-scoped, analyses et smoke battle.
- [x] Evidence Pack FG-020/053, frontière FG-206.
- [x] Commit isolé et état Git final.
