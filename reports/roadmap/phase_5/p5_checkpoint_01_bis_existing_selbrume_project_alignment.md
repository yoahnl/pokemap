# P5-CHECKPOINT-01-bis — Existing Selbrume Project Alignment Fix

## 1. Résumé exécutif

Ce bis corrige uniquement la trajectoire documentaire Phase 6.

Décision :

```text
SELBRUME_EXISTING_PROJECT_PATH = /Users/karim/Desktop/selbrume
```

La Phase 6 ne part pas de zéro. Elle doit utiliser le projet Selbrume existant
fourni par Karim comme base, l'auditer en P6-00, verrouiller un mini-parcours
golden slice court, puis proposer uniquement les corrections ou alignements
nécessaires.

Prochain lot exact corrigé :

```text
P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
```

Ce bis ne lance pas P6-00, ne modifie pas le projet Selbrume existant, ne crée
pas Selbrume final, ne modifie aucun code et ne modifie aucun test.

## 2. Pourquoi ce bis est nécessaire

Le checkpoint Phase 5 avait ouvert la Phase 6 avec une intention correcte :
assembler un golden slice Selbrume. Mais après clarification de Karim, il faut
éviter une lecture incorrecte :

```text
Créer Selbrume from scratch
```

La bonne trajectoire est :

```text
Auditer le Selbrume existant
-> identifier ce qui est déjà utilisable
-> décider du mini-parcours golden slice
-> corriger / compléter seulement ce qui manque
-> prouver runtime / save-load / validator
```

## 3. Dossier Selbrume existant fourni par Karim

Chemin fourni :

```text
/Users/karim/Desktop/selbrume
```

Résultat du test d'existence :

```text
SELBRUME_EXISTING_PROJECT_PATH exists
```

Indices de structure observés en lecture seule :

- `project.json` existe à la racine du dossier Selbrume ;
- des maps existent dans `maps/` ;
- un dialogue Yarn existe dans `dialogues/` ;
- des dossiers `assets/`, `assets/pokemon`, `assets/tilesets` existent ;
- des données Pokémon existent dans `data/pokemon/`.

Cette inspection est volontairement légère. L'audit complet du projet existant
est reporté à P6-00.

## 4. Inspection légère réalisée

Inspection autorisée et réalisée :

- vérifier que le chemin existe ;
- lister les fichiers de premier niveau et deuxième niveau ;
- lister les dossiers de premier niveau et deuxième niveau ;
- chercher `project.json` et les fichiers JSON.

Inspection non réalisée :

- aucune correction de données ;
- aucune migration ;
- aucun lancement runtime ;
- aucun validator ;
- aucun audit complet de contenu ;
- aucune modification du dossier `/Users/karim/Desktop/selbrume`.

## 5. Corrections apportées aux roadmaps

`MVP Selbrume/road_map_phase_6.md` a été corrigée pour dire explicitement :

- Phase 6 part du projet Selbrume existant fourni par Karim ;
- la phase ne recrée pas Selbrume from scratch ;
- P6-00 audite ce projet existant ;
- le mini-parcours golden slice sera choisi à partir de l'état réel du projet ;
- les lots Phase 6 sont orientés audit, alignement, mini-parcours, runtime,
  save/load et validator.

`MVP Selbrume/road_map_global.md` a été corrigée pour :

- pointer vers le nouveau prochain lot exact ;
- intégrer la décision utilisateur dans les décisions globales ;
- corriger l'objectif et le périmètre Phase 6 ;
- ajouter une entrée historique P5-CHECKPOINT-01-bis.

`MVP Selbrume/road_map_phase_5.md` a été corrigée sans rouvrir Phase 5 :

- Phase 5 reste clôturée avec réserves mineures ;
- P5-10 Audio reste reporté ;
- le prochain lot exact pointe vers l'audit du projet Selbrume existant.

## 6. Corrections apportées au rapport checkpoint

Le rapport `reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md`
a reçu une note corrective courte :

```text
La Phase 6 ne doit pas être interprétée comme une création de Selbrume from scratch.
Karim dispose déjà d'un projet Selbrume partiel :
/Users/karim/Desktop/selbrume
La Phase 6 doit auditer ce projet existant et l'utiliser comme base pour le golden slice.
```

Le prochain lot exact dans ce rapport a aussi été corrigé :

```text
P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
```

## 7. Ce qui n’a pas été fait

Ce bis ne fait pas les actions suivantes :

- pas de P6-00 ;
- pas d'audit complet du projet Selbrume existant ;
- pas de modification du dossier `/Users/karim/Desktop/selbrume` ;
- pas de modification de code ;
- pas de modification de test ;
- pas de création de feature ;
- pas de création de contenu Selbrume final ;
- pas de runtime lancé ;
- pas de validator lancé ;
- pas de build_runner ;
- pas de test ;
- pas d'analyze.

Justification tests/analyze :

```text
Aucun test ni analyze lancé, car ce bis est strictement documentaire et ne modifie aucun code.
```

## 8. Prochain lot exact corrigé

```text
P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
```

But de P6-00 corrigé :

```text
auditer le projet Selbrume existant fourni par Karim
identifier ce qui est déjà compatible PokeMap
verrouiller un mini-parcours golden slice court
classer les corrections / alignements nécessaires
fixer le prochain lot d'intégration
```

## 9. Evidence Pack

### Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie :

```text
/Users/karim/Project/pokemonProject
main
beb36d20 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b8997 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
a547ccc2 Ajoute P5-08 et P5-09 : Beta Runtime Smoke et Beta Playability Validator (code, tests et rapports)
2ac26e93 Ajoute P5-07 : Gameplay Save/Load Beta Roundtrip (test et rapport)
f7a0cfd6 Ajoute P5-06 : Capture Destination (Party/Box) Minimal Flow (code, tests et rapport)
ede6aa87 Ajoute P5-05 : Battle Rewards (Money/XP) Minimal Apply (code, test et rapport)
5ac1311c Ajoute P5-04 : Party/Bag Heal Minimal Operations (code, test et rapport)
857a3f3a Met à jour les fichiers pour la résolution du rendu des path patterns (éditeur et runtime)
9924607c Ajoute P5-03 : Starter Initial Party Minimal Flow (test et rapport)
45fc3247 Ajoute P5-02 : New Game Initial GameState Builder (code, tests et rapport)
```

Lecture de cette sortie :

- branche courante : `main` ;
- `git status --short --untracked-files=all` initial : sortie vide ;
- `git diff --stat` initial : sortie vide ;
- `git diff --name-only` initial : sortie vide.

### Inspection légère du dossier Selbrume existant

Commande :

```bash
test -d "/Users/karim/Desktop/selbrume" && echo "SELBRUME_EXISTING_PROJECT_PATH exists" || echo "SELBRUME_EXISTING_PROJECT_PATH missing"
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type f | sort | sed -n '1,120p'
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type d | sort | sed -n '1,120p'
find "/Users/karim/Desktop/selbrume" -iname 'project.json' -o -iname '*.json' | sort | sed -n '1,120p'
```

Sortie :

```text
SELBRUME_EXISTING_PROJECT_PATH exists
/Users/karim/Desktop/selbrume/dialogues/g.yarn
/Users/karim/Desktop/selbrume/maps/Selbrume.json
/Users/karim/Desktop/selbrume/maps/house 1.json
/Users/karim/Desktop/selbrume/maps/house 2.json
/Users/karim/Desktop/selbrume/maps/house 3.json
/Users/karim/Desktop/selbrume/maps/house 4.json
/Users/karim/Desktop/selbrume/maps/house 5.json
/Users/karim/Desktop/selbrume/maps/lab.json
/Users/karim/Desktop/selbrume/maps/pokémon center.json
/Users/karim/Desktop/selbrume/maps/pub.json
/Users/karim/Desktop/selbrume/maps/route 1.json
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/project.shadow59.before.json
/Users/karim/Desktop/selbrume
/Users/karim/Desktop/selbrume/assets
/Users/karim/Desktop/selbrume/assets/pokemon
/Users/karim/Desktop/selbrume/assets/tilesets
/Users/karim/Desktop/selbrume/data
/Users/karim/Desktop/selbrume/data/pokemon
/Users/karim/Desktop/selbrume/dialogues
/Users/karim/Desktop/selbrume/maps
/Users/karim/Desktop/selbrume/data/pokemon/catalogs/items.json
/Users/karim/Desktop/selbrume/data/pokemon/catalogs/moves.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/abomasnow.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/abra.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/accelgor.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aegislash.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aggron.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aipom.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/alakazam.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/alcremie.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/altaria.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/amaura.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/ambipom.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/amoonguss.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/ampharos.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/annihilape.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/anorith.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/appletun.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/applin.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/araquanid.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/arbok.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/arboliva.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/arcanine.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/archaludon.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/archen.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/archeops.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/arctibax.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/ariados.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/armaldo.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/armarouge.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aromatisse.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aron.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/arrokuda.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/aurorus.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/avalugg.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/axew.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/azumarill.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/azurill.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bagon.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/baltoy.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/banette.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/barbaracle.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/barboach.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/barraskewda.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/basculegion.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/basculin.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bastiodon.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/baxcalibur.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bayleef.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/beartic.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/beautifly.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/beedrill.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/beheeyem.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/beldum.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bellibolt.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bellossom.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bellsprout.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bergmite.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bewear.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bibarel.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bidoof.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/binacle.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bisharp.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/blastoise.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/blaziken.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/blipbug.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/blissey.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/blitzle.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/boldore.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/boltund.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bonsly.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bounsweet.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/braixen.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/brambleghast.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bramblin.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/braviary.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/breloom.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/brionne.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bronzong.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bronzor.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/budew.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/buizel.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bulbasaur.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/buneary.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/bunnelby.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/burmy.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/butterfree.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cacnea.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cacturne.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/camerupt.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/capsakid.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/carkol.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/carracosta.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/carvanha.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cascoon.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/caterpie.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/centiskorch.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/ceruledge.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cetitan.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cetoddle.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chandelure.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chansey.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/charcadet.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/charizard.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/charjabug.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/charmander.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/charmeleon.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cherrim.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cherubi.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chesnaught.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chespin.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chewtle.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chikorita.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chimchar.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chimecho.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chinchou.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/chingling.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cinccino.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/cinderace.json
/Users/karim/Desktop/selbrume/data/pokemon/evolutions/clamperl.json
```

### Fichiers lus

Commandes :

```bash
sed -n '1,260p' AGENTS.md
test -f agent_rules.md && sed -n '1,260p' agent_rules.md || echo "agent_rules.md absent"
test -f skills/README.md && sed -n '1,220p' skills/README.md || echo "skills/README.md absent"
sed -n '1,240p' "MVP Selbrume/road_map_global.md" && sed -n '500,840p' "MVP Selbrume/road_map_global.md"
sed -n '1,520p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,520p' "MVP Selbrume/road_map_phase_6.md"
sed -n '1,520p' reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md
```

Résultats utiles :

- `AGENTS.md` lu ;
- `agent_rules.md` lu ;
- `skills/README.md` lu ;
- `road_map_global.md` lu ;
- `road_map_phase_5.md` lu ;
- `road_map_phase_6.md` lu ;
- rapport checkpoint P5 lu.

### Sections modifiées de `road_map_phase_6.md`

Contenu complet de `MVP Selbrume/road_map_phase_6.md` après correction :

~~~text
# Phase 6 Roadmap — Selbrume Golden Slice réel

## Statut de la phase

Phase 6 ouverte par le checkpoint Phase 5.

Statut : 🟡 active

SELBRUME_EXISTING_PROJECT_PATH :

```text
/Users/karim/Desktop/selbrume
```

Lot courant : ➡️ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Prochain lot exact : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

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

- ➡️ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
- ⏳ P6-01 — Existing Selbrume Disk Layout Alignment V0
- ⏳ P6-02 — Selbrume Start Map / Spawn / New Game Wiring V0
- ⏳ P6-03 — Selbrume Initial Party / Bag Setup V0
- ⏳ P6-04 — Selbrume First Narrative Interaction V0
- ⏳ P6-05 — Selbrume First Trainer Battle Golden Slice V0
- ⏳ P6-06 — Selbrume Save/Load Golden Slice V0
- ⏳ P6-07 — Selbrume Beta Validator Pass V0
- ⏳ P6-08 — Selbrume Playable Runtime Smoke V0
- 🧭 P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

P6-00 : ➡️ prochain lot exact

Prochain lot exact :

```text
P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
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

## Roadmap

### ➡️ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Statut : prochain lot exact.

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

### ⏳ P6-01 — Existing Selbrume Disk Layout Alignment V0

But :

```text
aligner strictement le layout disque du projet Selbrume existant avec ce que le
runtime PokeMap peut charger.
```

### ⏳ P6-02 — Selbrume Start Map / Spawn / New Game Wiring V0

But :

```text
brancher une map de départ Selbrume, un spawn et un New Game minimal.
```

### ⏳ P6-03 — Selbrume Initial Party / Bag Setup V0

But :

```text
fournir une party initiale et un bag minimal utilisables dans le golden slice.
```

### ⏳ P6-04 — Selbrume First Narrative Interaction V0

But :

```text
prouver une première interaction narrative courte dans le mini-parcours choisi.
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
~~~

### Sections modifiées de `road_map_global.md`

Sections modifiées principales :

```text
Lot courant : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Prochain lot exact : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

- P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock : 🔜 prochain lot exact
```

```text
Objectif :
Auditer et réconcilier le projet Selbrume existant fourni par Karim afin d'en
extraire un premier Golden Slice court, jouable, validé et sauvegardable, sans
que l'agent génère tout le jeu à sa place.

Pourquoi :
Selbrume est le scénario de référence qui vérifie la grammaire complète avec un
cas concret, mais il doit rester un test du produit, pas un contenu fabriqué par
l’agent dans le repo. La Phase 6 ne part pas de zéro : elle doit utiliser le
projet existant situé à `/Users/karim/Desktop/selbrume` comme base.
```

```text
P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

P6-00 doit rester audit-first et cadrer l'assemblage Selbrume bêta depuis le
projet existant fourni par Karim : réutiliser les preuves Phase 5, inventorier
le contenu disponible, vérifier le chemin projet disque réel et verrouiller un
mini-parcours golden slice.
```

```text
- P5-CHECKPOINT-01-bis : Phase 6 doit partir du projet Selbrume existant fourni
  par Karim (`/Users/karim/Desktop/selbrume`), pas d'une création from scratch.
```

```text
- 2026-05-25 — P5-CHECKPOINT-01-bis — Correction documentaire ciblée :
  Phase 6 doit partir du projet Selbrume existant fourni par Karim
  (`/Users/karim/Desktop/selbrume`) et non d'une création from scratch. P6-00
  est recadré comme audit du projet existant et verrouillage du périmètre golden
  slice court : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope
  Lock.
```

### Sections modifiées de `road_map_phase_5.md`

```text
Prochain lot exact : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock
```

```text
Note P5-CHECKPOINT-01-bis :

P6-00 audite désormais le projet Selbrume existant fourni par Karim :
/Users/karim/Desktop/selbrume
Phase 6 ne part pas d'une création Selbrume from scratch.
```

```text
Phase 5 : clôturée avec réserves mineures.
P5-10 Audio : reporté hors scope Phase 5 immédiate.
Prochain lot exact : P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock.
```

### Section ajoutée au rapport checkpoint P5

```text
Correction P5-CHECKPOINT-01-bis :

La Phase 6 ne doit pas être interprétée comme une création de Selbrume from scratch.
Karim dispose déjà d'un projet Selbrume partiel :
/Users/karim/Desktop/selbrume
La Phase 6 doit auditer ce projet existant et l'utiliser comme base pour le golden slice.
```

### Contenu complet du rapport bis créé

Le présent fichier constitue le contenu complet du rapport bis créé. Les
sections 1 à 10 de ce document sont l'intégralité du rapport
`p5_checkpoint_01_bis_existing_selbrume_project_alignment.md`.

### Contrôles finaux

```text
git diff --check
Sortie : <vide>

git diff --stat
 MVP Selbrume/road_map_global.md                    | 43 +++++++----
 MVP Selbrume/road_map_phase_5.md                   | 14 +++-
 MVP Selbrume/road_map_phase_6.md                   | 83 +++++++++++++++-------
 ...checkpoint_01_gameplay_loop_readiness_review.md | 41 +++++++----
 4 files changed, 121 insertions(+), 60 deletions(-)

git diff --name-only
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
MVP Selbrume/road_map_phase_6.md
reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md

git status --short --untracked-files=all
 M "MVP Selbrume/road_map_global.md"
 M "MVP Selbrume/road_map_phase_5.md"
 M "MVP Selbrume/road_map_phase_6.md"
 M reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md
?? reports/roadmap/phase_5/p5_checkpoint_01_bis_existing_selbrume_project_alignment.md
```

### Contrôles explicites

- Aucun code n'a été modifié.
- Aucun test n'a été modifié.
- Aucun fichier du projet Selbrume existant n'a été modifié.
- Aucun fichier `packages/map_core/` n'a été modifié.
- Aucun fichier `packages/map_gameplay/` n'a été modifié.
- Aucun fichier `packages/map_battle/` n'a été modifié.
- Aucun fichier `packages/map_runtime/` n'a été modifié.
- Aucun fichier `packages/map_editor/` n'a été modifié.
- Aucun fichier `examples/playable_runtime_host/` n'a été modifié.
- Aucun `project.json`, `game_save.json`, `pubspec.yaml`, `pubspec.lock`,
  `*.g.dart` ou `*.freezed.dart` n'a été modifié.
- P6-00 n'a pas été exécuté.
- Selbrume final n'a pas été créé.
- Le projet Selbrume existant n'a pas été déplacé, normalisé ou corrigé.
- P5-10 Audio reste reporté.

## 10. Auto-review critique

- Ai-je modifié du code ? Non.
- Ai-je modifié des tests ? Non.
- Ai-je modifié le projet Selbrume existant ? Non.
- Ai-je lancé P6-00 ? Non.
- Ai-je corrigé la roadmap Phase 6 pour partir du projet existant ? Oui.
- Ai-je évité de présenter Phase 6 comme une création from scratch ? Oui.
- Ai-je conservé la clôture Phase 5 ? Oui.
- Ai-je gardé P5-10 Audio comme reporté ? Oui.
- Ai-je inclus le contenu / preuve de `road_map_phase_6.md` ? Oui, contenu
  complet reproduit dans l'Evidence Pack.
- Ai-je mis à jour le prochain lot exact ? Oui :
  `P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock`.
- Ai-je laissé des fichiers temporaires ? Non.
