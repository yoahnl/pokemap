# RM-029 Exhausted PP & Struggle V0 Implementation Plan

**Goal:** remplacer le dead-end `noLegalChoice` par un Struggle canonique
lorsque le Pokémon actif possède des moves mais qu’aucun n’est légalement
sélectionnable.

**Architecture:** `map_battle` possède la définition synthétique et la décision
canonique Struggle. Le moteur PSDK exécute cette attaque sans l’ajouter au
moveset ni consommer/persister de PP. `map_runtime` adapte ce choix synthétique
vers le menu legacy d’affichage, puis le soumet au moteur canonique.

**Policy V0:** puissance 50, physique, typeless via `unknown`, précision
always-hit, priorité 0, cible adverse, recul égal à 1/4 des PV max, aucun PP
persisté.

**Non-goals:** modifier les movesets sauvegardés, porter Struggle dans le moteur
legacy direct, ajouter une UI editor, changer la policy de switch trainer ou
promouvoir RM-053.

### Task 1: Contrat battle canonique

- [x] Définir la donnée Struggle synthétique et son slot interne réservé.
- [x] Exposer Struggle seulement si des moves existent et qu’aucun n’est légal.
- [x] Préserver switch, item, capture et fuite comme autres choix légaux.
- [x] Garder les états K.O./remplacement hors du fallback Struggle.

### Task 2: Exécution PSDK

- [x] Mapper la décision Struggle vers une action synthétique.
- [x] Exécuter dégâts, always-hit et recul 1/4 PV max.
- [x] Ne consommer aucun PP et ne jamais ajouter Struggle au write-back.
- [x] Donner le même fallback à l’IA lorsqu’elle ne peut ni agir autrement ni switcher.

### Task 3: Bridge et surface runtime

- [x] Ajouter Struggle uniquement au moveset de présentation legacy.
- [x] Mapper le choix de présentation vers la décision canonique.
- [x] Afficher FIGHT/Struggle au lieu d’un dead-end.
- [x] Préserver le moveset et les PP réels après le tour.

### Task 4: Validation et clôture

- [x] Tests battle positifs, négatifs, joueur, IA et recul.
- [x] Tests runtime adapter/menu/write-back.
- [x] Suites package-scoped, analyses et smoke battle.
- [x] Evidence Pack FG-041/052/053 et commit isolé.
