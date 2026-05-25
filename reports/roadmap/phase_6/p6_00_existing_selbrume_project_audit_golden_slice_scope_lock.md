# P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

## 1. Résumé exécutif

P6-00 a audité en lecture seule le projet Selbrume existant fourni par Karim :

```text
/Users/karim/Desktop/selbrume
```

Verdict court :

- le projet existe et contient un `project.json` lisible ;
- les 10 maps déclarées sont présentes sur disque ;
- les 30 tilesets déclarés sont présents sur disque ;
- la map `Selbrume` contient un spawn joueur exploitable ;
- la map `route 1` contient des zones de rencontre et une table d'encounter ;
- les données Pokémon utiles à un premier smoke existent en grande partie ;
- aucun trainer n'est déclaré ;
- le dialogue existant est un placeholder non branché ;
- le contrat de start map n'est pas explicite et doit être verrouillé avant le reste.

Golden slice candidat retenu :

```text
Selbrume spawn -> première interaction narrative courte -> route 1
-> rencontre/capture route 1 -> premier trainer battle minimal
-> reward -> save/load -> validator beta -> runtime smoke
```

Prochain lot exact recommandé :

```text
P6-01 — Existing Selbrume Loadability / Start Map Contract V0
```

Aucun code, aucun test et aucun fichier du projet Selbrume existant n'ont été modifiés.

## 2. Sources lues

Sources de gouvernance lues :

```text
AGENTS.md
agent_rules.md
skills/README.md
pokemap_roadmap_mecaniques_fangame.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_6.md
MVP Selbrume/road_map_phase_5.md
reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md
reports/roadmap/phase_5/p5_checkpoint_01_bis_existing_selbrume_project_alignment.md
```

Sources techniques lues pour juger la compatibilité probable :

```text
packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
packages/map_core/lib/src/validation/beta_playability_validator.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
```

Projet Selbrume inspecté en lecture seule :

```text
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/*.json
/Users/karim/Desktop/selbrume/dialogues/*.yarn
/Users/karim/Desktop/selbrume/data/pokemon/catalogs/*.json
/Users/karim/Desktop/selbrume/data/pokemon/species/*.json
/Users/karim/Desktop/selbrume/data/pokemon/learnsets/*.json
/Users/karim/Desktop/selbrume/assets/tilesets/*
```

## 3. Gate 0

Commande :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
```

`git status --short --untracked-files=all` initial :

```text
Sortie : <vide>
```

`git diff --stat` initial :

```text
Sortie : <vide>
```

`git diff --name-only` initial :

```text
Sortie : <vide>
```

`git log --oneline -n 10` initial :

```text
a54b6001 Ajoute le rapport P5-Checkpoint-01-bis et met à jour les roadmaps
beb36d20 Ajoute road_map_phase_6.md et le rapport P5-Checkpoint-01, met à jour road_map_global.md et road_map_phase_5.md
a04b8997 Ajoute P5-10 : Scope Audio Out of Scope Checkpoint Redirect (rapport)
a547ccc2 Ajoute P5-08 et P5-09 : Beta Runtime Smoke et Beta Playability Validator (code, tests et rapports)
2ac26e93 Ajoute P5-07 : Gameplay Save/Load Beta Roundtrip (test et rapport)
f7a0cfd6 Ajoute P5-06 : Capture Destination (Party/Box) Minimal Flow (code, tests et rapport)
ede6aa87 Ajoute P5-05 : Battle Rewards (Money/XP) Minimal Apply (code, test et rapport)
5ac1311c Ajoute P5-04 : Party/Bag Heal Minimal Operations (code, test et rapport)
857a3f3a Met à jour les fichiers pour la résolution du rendu des path patterns (éditeur et runtime)
9924607c Ajoute P5-03 : Starter Initial Party Minimal Flow (test et rapport)
```

Commande d'existence du projet Selbrume :

```bash
test -d "/Users/karim/Desktop/selbrume" && echo "SELBRUME_EXISTING_PROJECT_PATH exists" || echo "SELBRUME_EXISTING_PROJECT_PATH missing"
```

Sortie :

```text
SELBRUME_EXISTING_PROJECT_PATH exists
```

## 4. Projet Selbrume existant audité

Chemin audité :

```text
/Users/karim/Desktop/selbrume
```

Nature de l'inspection :

```text
lecture seule
inventaire disque
parsing JSON sans écriture
résumé des maps
résumé des dialogues
résumé des données Pokémon
diagnostic de compatibilité probable
```

Ce que P6-00 n'a pas fait sur ce dossier :

```text
aucune modification
aucune migration
aucune correction de project.json
aucune création de map
aucune création de dialogue
aucune création de trainer
aucun lancement runtime
aucun lancement validator
```

## 5. Inventaire disque

### 5.1 Listing borné des fichiers

Commande :

```bash
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type f | sort | sed -n '1,200p'
```

Sortie utile :

```text
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
```

### 5.2 Listing borné des dossiers

Commande :

```bash
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type d | sort | sed -n '1,200p'
```

Sortie :

```text
/Users/karim/Desktop/selbrume
/Users/karim/Desktop/selbrume/assets
/Users/karim/Desktop/selbrume/assets/pokemon
/Users/karim/Desktop/selbrume/assets/tilesets
/Users/karim/Desktop/selbrume/data
/Users/karim/Desktop/selbrume/data/pokemon
/Users/karim/Desktop/selbrume/dialogues
/Users/karim/Desktop/selbrume/maps
```

### 5.3 Listing borné des JSON

Commande :

```bash
find "/Users/karim/Desktop/selbrume" -iname 'project.json' -o -iname '*.json' | sort | sed -n '1,200p'
```

Sortie utile :

```text
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
```

La commande est volontairement bornée à 200 lignes. Le signal important pour P6-00 est que `project.json`, les maps, les catalogues `items` et `moves`, ainsi que les dossiers Pokémon sont présents.

### 5.4 Matrice inventaire disque

| Zone | Chemins détectés | Existe ? | Utilisable Phase 6 ? | Problèmes visibles | Décision |
|---|---|---:|---:|---|---|
| `project.json` | `/Users/karim/Desktop/selbrume/project.json` | oui | oui | start map non explicite | P6-01 doit verrouiller le contrat |
| `maps/` | 10 fichiers JSON | oui | oui | plusieurs intérieurs vides | garder comme base |
| `dialogues/` | `dialogues/g.yarn` | oui | partiel | placeholder non branché | P6-03 |
| `assets/` | `assets/pokemon`, `assets/tilesets` | oui | oui | inventaire large | garder |
| `assets/tilesets/` | 31 fichiers détectés, 30 déclarés | oui | oui | un asset extra non déclaré possible | non bloquant |
| `assets/pokemon/` | 5514 fichiers détectés | oui | oui | hors scope P6-00 | garder |
| `data/pokemon/catalogs` | `moves.json`, `items.json` | oui | oui | catalogues optionnels déclarés absents | P6-07 si validator le demande |
| `data/pokemon/species` | 986 fichiers | oui | oui | noms préfixés par dex number | runtime loader sait scanner par `id` |
| `data/pokemon/moves` ou moves catalog | `catalogs/moves.json` | oui | oui | pas de dossier moves séparé requis | garder |
| `trainers` | liste manifest vide | non | non | aucun trainer | P6-05 |
| `encounters` | 1 table dans manifest, zones sur `route 1` | oui | oui | capture item/bag non authorés | P6-04 |
| `scenarios/scripts` | 2 scénarios, 0 scripts | partiel | partiel | scénarios non branchés clairement | P6-03 |
| save data | aucun fichier de save attendu | non | oui via moteur | pas une donnée projet | P6-06 |

## 6. Analyse project.json

Commande de parsing read-only :

```bash
python3 - <<'PY'
import json
from pathlib import Path

path = Path("/Users/karim/Desktop/selbrume/project.json")
data = json.loads(path.read_text())
print("project_json_path =", path)
print("top_level_keys =", sorted(data.keys()))
for key in sorted(data.keys()):
    value = data[key]
    if isinstance(value, list):
        print(f"{key}: list[{len(value)}]")
    elif isinstance(value, dict):
        print(f"{key}: dict[{len(value)}] keys={sorted(value.keys())}")
    else:
        print(f"{key}: {type(value).__name__} = {value!r}")
PY
```

Sortie :

```text
project_json_path = /Users/karim/Desktop/selbrume/project.json
top_level_keys = ['characters', 'dialogueFolders', 'dialogues', 'elementCategories', 'elements', 'encounterTables', 'environmentPresets', 'globalProperties', 'groups', 'maps', 'name', 'pathCategories', 'pathPatternPresets', 'pathPresets', 'pokemon', 'scenarios', 'scripts', 'settings', 'shadowCatalog', 'surfaceCatalog', 'terrainCategories', 'terrainPresets', 'tilesetFolders', 'tilesets', 'trainers', 'version']
characters: list[4]
dialogueFolders: list[0]
dialogues: list[1]
elementCategories: list[5]
elements: list[66]
encounterTables: list[1]
environmentPresets: list[4]
globalProperties: dict[0] keys=[]
groups: list[3]
maps: list[10]
name: str = 'Selbrume'
pathCategories: list[0]
pathPatternPresets: list[1]
pathPresets: list[9]
pokemon: dict[7] keys=['catalogFiles', 'dataRoot', 'enabled', 'evolutionsDir', 'learnsetsDir', 'mediaDir', 'speciesDir']
scenarios: list[2]
scripts: list[0]
settings: dict[6] keys=['defaultMapHeight', 'defaultMapWidth', 'defaultPlayerCharacterId', 'displayScale', 'tileHeight', 'tileWidth']
shadowCatalog: dict[1] keys=['profiles']
surfaceCatalog: dict[3] keys=['animations', 'atlases', 'presets']
terrainCategories: list[0]
terrainPresets: list[2]
tilesetFolders: list[7]
tilesets: list[30]
trainers: list[0]
version: str = 'v1'
```

Résumé :

- nom projet : `Selbrume` ;
- version : `v1` ;
- maps : 10 ;
- tilesets : 30 ;
- dialogues : 1 ;
- scenarios : 2 ;
- scripts : 0 ;
- trainers : 0 ;
- encounter tables : 1 ;
- configuration Pokémon activée ;
- `defaultPlayerCharacterId = vova`, avec personnage existant ;
- aucun champ start map explicite identifié pendant P6-00.

Décision :

```text
project.json est exploitable comme base, mais P6-01 doit verrouiller comment
le runtime et le New Game choisissent la map de départ Selbrume au lieu de
dépendre de la première map déclarée.
```

## 7. Analyse des maps

### 7.1 Maps déclarées et présentes

Maps détectées :

```text
route 1 -> maps/route 1.json
Selbrume -> maps/Selbrume.json
house 1 -> maps/house 1.json
house 2 -> maps/house 2.json
house 3 -> maps/house 3.json
house 4 -> maps/house 4.json
house 5 -> maps/house 5.json
pokémon center -> maps/pokémon center.json
pub -> maps/pub.json
lab -> maps/lab.json
```

Toutes les maps déclarées dans `project.json` existent sur disque.

### 7.2 Résumé des maps inspectées

```text
route 1:
  role: exterior
  size: 45x45
  layers: 6
  placed tiles: 68
  entities: 0
  spawns: 0
  defaultSpawnId: None
  warps: 0
  zones: 5
  connections: west -> Selbrume
  usage probable: route de rencontre / capture

Selbrume:
  role: exterior
  size: 55x55
  layers: 16
  placed tiles: 1179
  entities: 1
  spawns: 1
  defaultSpawnId: None
  spawn id: spawn
  spawn role: player_start
  spawn pos: x=17, y=24
  facing: south
  warps: 3
  zones: 0
  connections: east -> route 1
  usage probable: départ golden slice

house 1:
  role: interior
  size: 45x45
  layers: 3
  placed tiles: 0
  entities: 0
  warps: 1 back to Selbrume
  usage probable: intérieur placeholder

house 2:
  role: exterior
  size: 45x45
  layers: 3
  placed tiles: 0
  entities: 0
  warps: 1 back to Selbrume
  usage probable: intérieur placeholder avec role à vérifier

house 3, house 4, house 5, pokémon center, pub, lab:
  size: 45x45
  layers: 3
  placed tiles: 0
  entities: 0
  warps: 0
  usage probable: placeholders
```

### 7.3 Spawn et start map

Meilleure candidate start map :

```text
map: Selbrume
spawn entity id: spawn
role: player_start
position: x=17, y=24
facing: south
```

Point important :

```text
mapMetadata.defaultSpawnId n'est pas renseigné.
Le resolver P5-02 peut utiliser un fallback sur le premier player_start,
mais le contrat projet Selbrume doit être explicite en P6-01.
```

Risque :

```text
Si aucun startMapId n'est fourni au validator P5-09, celui-ci utilise la
première map du manifest. Ici, la première map est route 1, qui n'a pas de
spawn joueur. Le validator risque donc de signaler une start map invalide tant
que Selbrume n'est pas choisie explicitement.
```

### 7.4 Transitions

Transitions exploitables :

```text
Selbrume -> route 1 via connection east
route 1 -> Selbrume via connection west
Selbrume -> house 1 via warp "to house 1"
Selbrume -> house 2 via warp "to house 2"
house 1 -> Selbrume
house 2 -> Selbrume
```

Transition suspecte :

```text
warp "to lab" sur Selbrume cible actuellement Selbrume à la même position.
```

Décision :

```text
Le golden slice doit privilégier la transition Selbrume -> route 1, car route 1
contient déjà des zones d'encounter. Les maisons et le lab peuvent rester hors
du premier parcours si elles ne sont pas nécessaires.
```

## 8. Analyse narrative / dialogues / events

Dialogues :

```text
dialogue id: g
path: dialogues/g.yarn
exists: true
defaultStartNode: None
```

Contenu utile du dialogue :

```text
title: g
---
(Begin editing your dialogue here.)
===
```

Scénarios :

```text
global_story:
  kind: globalStory
  entry: start
  nodes: 2
  edges: 1
  outcomes: 0

test:
  kind: localEventFlow
  entry: start
  nodes: 4
  edges: 3
  outcomes: 0
  contient un sourceEntityInteract
  contient un showMessage avec message vide
```

Conclusion narrative :

- une base de scénario existe ;
- un dialogue Yarn existe ;
- aucun premier dialogue jouable n'est réellement prêt ;
- aucun lien fiable map entity -> dialogue/event n'a été identifié ;
- aucun outcome/progression narratif exploitable n'a été observé.

Décision :

```text
P6-03 doit créer ou brancher une première interaction narrative courte à partir
de l'existant, sans transformer Selbrume en campagne complète.
```

## 9. Analyse battle / trainers / encounters

Trainers :

```text
trainers_total = 0
```

Il n'existe pas de premier trainer battle authoré dans le manifest.

Encounter table :

```text
id: grass_path_route_1
kind: walk
entries:
  speciesId: pidgeotto
  minLevel: 1
  maxLevel: 5
  weight: 1
```

Zones d'encounter :

```text
map: route 1
zones: 5
kind: encounter
encounterTableId: grass_path_route_1
encounterKind: walk
```

Species de l'encounter :

```text
pidgeotto
```

Présence des données species :

```text
data/pokemon/species/0017-pidgeotto.json existe
id JSON: pidgeotto
```

Présence learnset observée :

```text
data/pokemon/learnsets/pidgeotto.json existe
```

Décision :

```text
Le premier chemin combat le plus réaliste commence par route 1 et son encounter
existant. Le premier trainer battle devra être ajouté plus tard, en P6-05, car
aucun trainer n'est authoré aujourd'hui.
```

## 10. Analyse assets / Pokémon data

Tilesets :

```text
tilesets déclarés: 30
tilesets déclarés présents sur disque: 30
```

Exemples de tilesets déclarés présents :

```text
grass_soft_flowers
deep_water
new_pavement_new
selbrume_all_sprite
grass_sprite
water_edge_only
beach_tile
dirt_path
pavement_path
mael
lyra
timi
route_1
haute_herbe
```

Configuration Pokémon :

```text
enabled: true
dataRoot: data/pokemon
speciesDir: data/pokemon/species
learnsetsDir: data/pokemon/learnsets
evolutionsDir: data/pokemon/evolutions
mediaDir: data/pokemon/media
```

Inventaire Pokémon observé :

```text
species files: 986
learnset files: 949
evolution files: 814
media files: 986
```

Catalogues déclarés :

```text
moves -> data/pokemon/catalogs/moves.json -> exists true -> entries 954
items -> data/pokemon/catalogs/items.json -> exists true -> entries 2176
abilities -> absent
types -> absent
growth_rates -> absent
natures -> absent
egg_groups -> absent
habitats -> absent
encounter_rules -> absent
generations -> absent
version_groups -> absent
```

Lecture des loaders :

```text
RuntimePokemonSpeciesLoader peut scanner les fichiers JSON du dossier species
et matcher le champ id. Le préfixe numérique des filenames n'est donc pas un
blocage immédiat pour pidgeotto.

RuntimeMoveCatalogLoader attend un catalog moves déclaré. Ce catalog existe.
```

Décision :

```text
Les données Pokémon sont suffisantes pour préparer un premier smoke technique
encounter/battle, sous réserve de vérifier les moves effectivement assignés aux
créatures utilisées dans le golden slice.
```

## 11. Compatibilité runtime probable

### 11.1 Références disque

Check de références en lecture seule :

```text
maps déclarées: 10
maps manquantes: []
tilesets déclarés: 30
tilesets manquants: []
dialogues déclarés: 1
dialogues manquants: []
```

### 11.2 Matrice compatibilité runtime

| Sujet | État observé | Preuve | Risque runtime | Lot concerné | Décision |
|---|---|---|---|---|---|
| `project.json` lisible | oui | parsing JSON OK | faible | P6-01 | charger en smoke |
| maps déclarées | oui, 10 | manifest | faible | P6-01 | garder |
| maps présentes sur disque | oui | check chemins | faible | P6-01 | garder |
| tilesets référencés | oui, 30 | manifest | faible | P6-01 | garder |
| tilesets présents sur disque | oui, 30/30 | check chemins | faible | P6-01 | garder |
| dialogues référencés | oui, 1 | manifest | moyen | P6-03 | contenu placeholder |
| dialogues présents sur disque | oui | `dialogues/g.yarn` | moyen | P6-03 | brancher ou remplacer minimalement |
| start map | non explicite | première map = route 1, candidate réelle = Selbrume | élevé | P6-01 | verrouiller |
| spawn | oui sur Selbrume | entity `spawn`, role `player_start` | moyen | P6-01 | expliciter ou tester fallback |
| party initiale | non authorée | aucun starter config | élevé | P6-02 | ajouter configuration minimale plus tard |
| bag initial | non authoré | aucun setup bag identifié | élevé | P6-02/P6-04 | prévoir capture source |
| trainer battle | absent | `trainers: list[0]` | élevé | P6-05 | créer un trainer minimal plus tard |
| encounter/capture | partiel | route 1 + pidgeotto | moyen | P6-04 | exploitable si bag/source capture existe |
| save/load | moteur prouvé Phase 5, pas Selbrume | rapports P5-07/P5-08 | moyen | P6-06 | prouver sur projet existant |
| validator bêta | probable diagnostics | start map/starter/trainer | élevé | P6-07 | traiter après alignements |

## 12. Risques validator bêta

Risques attendus si le validator P5-09 est lancé sans contexte adapté :

```text
start map:
  le validator peut choisir route 1 comme première map manifest
  route 1 ne contient pas de player_start
  diagnostic probable: missingPlayerSpawn ou invalid start map

spawn:
  Selbrume contient un player_start
  defaultSpawnId n'est pas renseigné
  diagnostic possible si le contexte exige un defaultSpawnId explicite

initial party:
  aucun starter / initial party source authoré
  diagnostic probable warning/info

trainers:
  aucun trainer déclaré
  diagnostic probable si requiresTrainerBattle = true

species/moves:
  pidgeotto existe
  moves catalog existe
  risque surtout lié aux moves choisis pour une future équipe trainer

capture:
  encounter route 1 existe
  source de capture / bag initial non authorée
  diagnostic probable si requiresCapture = true
```

Décision :

```text
Ne pas chercher à faire passer le validator en P6-00. Le validator pass doit
arriver après les alignements start map, party/bag, encounter/capture et trainer.
```

## 13. Golden slice candidat

### 13.1 Candidat retenu

```text
Départ:
  map: Selbrume
  spawn: spawn
  position: x=17, y=24
  facing: south

Étape 1:
  première interaction narrative courte à créer ou brancher depuis l'existant
  objectif: une phrase, un flag ou un event minimal

Étape 2:
  déplacement vers route 1 via connection est/ouest

Étape 3:
  rencontre route 1 via grass_path_route_1
  species: pidgeotto
  fallback capture possible après bag/capture source

Étape 4:
  premier trainer battle minimal une fois un trainer authoré
  reward money + level-up direct minimal selon preuves Phase 5

Étape 5:
  save/load disque sur l'état Selbrume

Étape 6:
  validator bêta

Étape 7:
  runtime smoke jouable court
```

### 13.2 Fallback minimal si le contenu narratif/trainer reste trop incomplet

```text
Selbrume spawn -> route 1 -> encounter pidgeotto -> capture minimale
-> save/load -> validator partiel
```

Ce fallback ne remplace pas le premier trainer battle : il permet seulement de garder un mini-parcours prouvable si le contenu trainer doit être authoré plus tard dans Phase 6.

### 13.3 Matrice contenu golden slice

| Brique | Existe déjà ? | Chemin / preuve | Réutilisable ? | Gap | Lot recommandé |
|---|---:|---|---:|---|---|
| map de départ | oui | `maps/Selbrume.json` | oui | contrat start map non explicite | P6-01 |
| spawn de départ | oui | entity `spawn`, role `player_start` | oui | `defaultSpawnId` absent | P6-01 |
| premier PNJ / interaction | non | aucune entity narrative fiable | non | créer/brancher interaction courte | P6-03 |
| premier dialogue | partiel | `dialogues/g.yarn` | faible | placeholder | P6-03 |
| première scène / event | partiel | scenario `test` | faible | message vide, lien map non clair | P6-03 |
| premier trainer | non | `trainers: list[0]` | non | créer trainer minimal | P6-05 |
| premier battle setup | partiel | encounter route 1 existe | oui pour wild, non pour trainer | authorer trainer battle | P6-04/P6-05 |
| reward minimal | non dans contenu | opérations Phase 5 prouvées | oui côté moteur | lier à trainer battle | P6-05 |
| save/load | oui côté moteur | P5-07/P5-08 | à prouver sur Selbrume | smoke Selbrume requis | P6-06 |
| validator pass | oui côté moteur | P5-09 | à prouver sur Selbrume | diagnostics probables | P6-07 |
| runtime smoke | oui côté moteur | P5-08 | à prouver sur Selbrume | dépend des lots précédents | P6-08 |

## 14. Gaps classés

| Gap | Classification | Sévérité | Preuve | Décision |
|---|---|---:|---|---|
| Start map non explicite | Bloquant P6-01 | Critical | première map manifest = `route 1`, candidate réelle = `Selbrume` | P6-01 doit verrouiller le contrat |
| `defaultSpawnId` absent sur Selbrume | Bloquant golden slice | High | spawn existe mais `defaultSpawnId=None` | P6-01 doit tester ou renseigner le comportement attendu |
| Dialogue Yarn placeholder | À traiter pendant Phase 6 | Medium | `g.yarn` contient texte placeholder | P6-03 |
| Scénario non branché clairement | À traiter pendant Phase 6 | Medium | scenario `test`, message vide, no outcomes | P6-03 |
| Aucun trainer | Bloquant golden slice trainer | High | `trainers: list[0]` | P6-05 |
| Initial party non authorée | Bloquant golden slice | High | aucune source starter/party manifest | P6-02 |
| Bag/capture source non authorée | Bloquant capture slice | High | encounter existe, pas source ball/bag | P6-02/P6-04 |
| Warps intérieurs incomplets | À traiter pendant Phase 6 | Medium | `to lab` cible Selbrume | éviter dans le premier parcours ou corriger lot dédié |
| Plusieurs maps intérieures vides | Report post-golden-slice | Low | placed tiles 0, no entities | ne pas bloquer route courte |
| Catalogues Pokémon optionnels absents | À traiter pendant Phase 6 | Medium | only moves/items exist among catalogFiles | vérifier besoins validator/runtime |
| Audio absent | Report Phase 7 ou chantier dédié | Low | P5-10 reporté | non bloquant |
| XP persistée complète absente | Non-scope | Low | Phase 5 a retenu level-up direct | ne pas rouvrir |
| Moves learned / évolution absents | Non-scope | Low | hors Phase 6 golden slice | ne pas rouvrir |
| Boot Flow complet absent | Non-scope | Low | non objectif Phase 6 | ne pas créer |

## 15. Roadmap Phase 6 recommandée

### 15.1 Décision

La roadmap Phase 6 reste courte, mais P6-01 est renommé pour refléter le vrai premier risque observé :

```text
P6-01 — Existing Selbrume Loadability / Start Map Contract V0
```

Motif :

```text
Le layout disque est globalement présent. Le premier risque n'est pas de créer
un squelette from scratch, mais de prouver que le projet existant charge et que
la start map Selbrume est sélectionnée explicitement avec son spawn.
```

### 15.2 Matrice de décision des lots Phase 6

| Lot | Garder / Renommer / Ajouter / Supprimer | Justification | Dépendance | Niveau de risque |
|---|---|---|---|---|
| P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock | garder, terminé | audit réalisé | aucune | faible |
| P6-01 — Existing Selbrume Loadability / Start Map Contract V0 | renommer | le problème immédiat est start map/loadability | P6-00 | élevé |
| P6-02 — Selbrume Initial Party / Bag Setup V0 | garder | party/bag non authorés | P6-01 | élevé |
| P6-03 — Selbrume First Narrative Interaction V0 | garder | dialogue/scenario existent mais non exploitables | P6-01/P6-02 | moyen |
| P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0 | renommer | route 1 possède déjà encounter zones | P6-02 | moyen |
| P6-05 — Selbrume First Trainer Battle Golden Slice V0 | garder | aucun trainer déclaré | P6-03/P6-04 | élevé |
| P6-06 — Selbrume Save/Load Golden Slice V0 | garder | Phase 5 prouvée, Selbrume à prouver | P6-05 | moyen |
| P6-07 — Selbrume Beta Validator Pass V0 | garder | diagnostics attendus | P6-06 | moyen |
| P6-08 — Selbrume Playable Runtime Smoke V0 | garder | preuve finale courte runtime | P6-07 | moyen |
| P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review | garder | fermeture Phase 6 | P6-08 | faible |

## 16. Prochain lot exact

Prochain lot exact verrouillé :

```text
P6-01 — Existing Selbrume Loadability / Start Map Contract V0
```

Objectif recommandé :

```text
prouver ou corriger minimalement la charge du projet Selbrume existant et fixer
le contrat de start map / spawn sans créer de contenu final.
```

Contraintes à conserver :

```text
ne pas créer Selbrume final
ne pas créer Boot Flow
ne pas créer UI premium
ne pas modifier les systèmes Pokémon complets
ne pas démarrer P6-02
```

## 17. Ce qui n'a pas été fait

Commandes non lancées :

```text
tests: Commande non lancée : P6-00 est un audit documentaire read-only.
analyze: Commande non lancée : aucun code modifié.
runtime: Commande non lancée : P6-00 ne doit pas lancer le runtime.
validator: Commande non lancée : P6-00 doit seulement prévoir les risques validator.
build_runner: Commande non lancée : aucun modèle/code généré modifié.
```

Actions non faites :

```text
aucune modification du projet Selbrume existant
aucune correction de project.json
aucune création de map
aucune création de trainer
aucune création de dialogue
aucune création de starter
aucune création de bag
aucune modification de code PokeMap
aucune modification de test
aucun démarrage de P6-01
```

## 18. Evidence Pack

### 18.1 Commandes exécutées

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 10
test -d "/Users/karim/Desktop/selbrume" && echo "SELBRUME_EXISTING_PROJECT_PATH exists" || echo "SELBRUME_EXISTING_PROJECT_PATH missing"
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type f | sort | sed -n '1,200p'
find "/Users/karim/Desktop/selbrume" -maxdepth 2 -type d | sort | sed -n '1,200p'
find "/Users/karim/Desktop/selbrume" -iname 'project.json' -o -iname '*.json' | sort | sed -n '1,200p'
sed -n '1,260p' AGENTS.md
sed -n '1,260p' agent_rules.md
sed -n '1,220p' skills/README.md
sed -n '1,260p' pokemap_roadmap_mecaniques_fangame.md
sed -n '1,420p' "MVP Selbrume/road_map_global.md"
sed -n '1,1320p' "MVP Selbrume/road_map_phase_6.md"
sed -n '1,1320p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,340p' reports/roadmap/phase_5/p5_checkpoint_01_gameplay_loop_readiness_review.md
sed -n '1,340p' reports/roadmap/phase_5/p5_checkpoint_01_bis_existing_selbrume_project_alignment.md
sed -n '1,260p' packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart
sed -n '1,260p' packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
sed -n '1,220p' packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
sed -n '1,320p' packages/map_core/lib/src/validation/beta_playability_validator.dart
sed -n '1,220p' packages/map_gameplay/lib/src/player_spawn_resolver.dart
python3 - <<'PY'
import json
from pathlib import Path
path = Path("/Users/karim/Desktop/selbrume/project.json")
data = json.loads(path.read_text())
print("project_json_path =", path)
print("top_level_keys =", sorted(data.keys()))
for key in sorted(data.keys()):
    value = data[key]
    if isinstance(value, list):
        print(f"{key}: list[{len(value)}]")
    elif isinstance(value, dict):
        print(f"{key}: dict[{len(value)}] keys={sorted(value.keys())}")
    else:
        print(f"{key}: {type(value).__name__} = {value!r}")
PY
mkdir -p reports/roadmap/phase_6
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
```

### 18.2 Fichiers créés

```text
reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
```

Le présent fichier est le rapport P6-00 complet.

### 18.3 Fichiers modifiés

```text
MVP Selbrume/road_map_phase_6.md
```

### 18.4 Sections modifiées de `road_map_phase_6.md`

Sections ajoutées ou mises à jour :

```text
Lot courant : ✅ P6-00 — Existing Selbrume Project Audit / Golden Slice Scope Lock

Prochain lot exact : P6-01 — Existing Selbrume Loadability / Start Map Contract V0

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
```

Section `Résultat P6-00` ajoutée :

```text
Audit réalisé en lecture seule :

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

Golden slice candidat ajouté :

```text
Départ : map Selbrume, spawn entity id "spawn", facing south
Étape 1 : première interaction narrative courte à créer / brancher
Étape 2 : transition Selbrume -> route 1 via connexion est/ouest
Étape 3 : rencontre route 1, puis trainer battle dès qu'un trainer minimal existe
Étape 4 : reward minimal
Étape 5 : save/load
Étape 6 : validator bêta
```

### 18.5 Résultat test existence dossier Selbrume

```text
SELBRUME_EXISTING_PROJECT_PATH exists
```

### 18.6 Liste des maps détectées

```text
maps/Selbrume.json
maps/house 1.json
maps/house 2.json
maps/house 3.json
maps/house 4.json
maps/house 5.json
maps/lab.json
maps/pokémon center.json
maps/pub.json
maps/route 1.json
```

### 18.7 Liste des dialogues détectés

```text
dialogues/g.yarn
```

### 18.8 Résumé des données Pokémon détectées

```text
data/pokemon/catalogs/items.json
data/pokemon/catalogs/moves.json
data/pokemon/species: 986 fichiers
data/pokemon/learnsets: 949 fichiers
data/pokemon/evolutions: 814 fichiers
data/pokemon/media: 986 fichiers
species pidgeotto: data/pokemon/species/0017-pidgeotto.json
learnset pidgeotto: data/pokemon/learnsets/pidgeotto.json
```

### 18.9 Contrôles finaux

`git diff --check` final :

```text
Sortie : <vide>
```

`git diff --stat` final :

```text
 MVP Selbrume/road_map_phase_6.md | 82 ++++++++++++++++++++++++++++++----------
 1 file changed, 62 insertions(+), 20 deletions(-)
```

`git diff --name-only` final :

```text
MVP Selbrume/road_map_phase_6.md
```

`git status --short --untracked-files=all` final :

```text
 M "MVP Selbrume/road_map_phase_6.md"
?? reports/roadmap/phase_6/p6_00_existing_selbrume_project_audit_golden_slice_scope_lock.md
```

### 18.10 Confirmations

```text
aucun code modifié: oui
aucun test modifié: oui
aucun fichier packages/map_core modifié: oui
aucun fichier packages/map_gameplay modifié: oui
aucun fichier packages/map_runtime modifié: oui
aucun fichier examples/playable_runtime_host modifié: oui
/Users/karim/Desktop/selbrume non modifié: oui
P6-01 non lancé: oui
runtime non lancé: oui
validator non lancé: oui
tests non lancés: oui
analyze non lancé: oui
```

## 19. Auto-review critique

- Ai-je modifié du code ? Non.
- Ai-je modifié des tests ? Non.
- Ai-je modifié le projet Selbrume existant ? Non.
- Ai-je lancé P6-01 ? Non.
- Ai-je créé du contenu Selbrume ? Non.
- Ai-je lancé le runtime ? Non.
- Ai-je lancé le validator ? Non.
- Ai-je distingué audit léger, audit complet et correction ? Oui : P6-00 audite et recommande, les corrections commencent en P6-01.
- Ai-je choisi un golden slice trop gros ? Non : le parcours est court et peut être réduit au fallback route 1 si besoin.
- Ai-je identifié un prochain lot exact unique ? Oui : `P6-01 — Existing Selbrume Loadability / Start Map Contract V0`.
- Ai-je gardé Phase 6 bornée ? Oui.
- Ai-je évité de rouvrir la parité Pokémon ? Oui.
- Ai-je évité de modifier `road_map_global.md` et `road_map_phase_5.md` ? Oui.
- Ai-je inclus les preuves de `project.json`, maps, dialogues et data ? Oui.
- Ai-je laissé des fichiers temporaires ? Non.
