# P5-00 — Phase 5 Roadmap Recalibration / Gameplay Loop Audit

## 1. Résumé exécutif

P5-00 confirme que la Phase 5 peut commencer, mais la roadmap initiale devait
être recalibrée.

Verdict critique :

```text
La roadmap Phase 5 actuelle était trop documentaire dans plusieurs intitulés.
Elle risquait de produire des "reviews", "contracts", "decisions" et "plans"
au lieu de preuves gameplay concrètes.
```

Décision :

```text
Phase 5 : ouverte.
P5-00 : audit-only validable.
Roadmap Phase 5 : recalibrée vers des preuves gameplay.
Prochain lot exact : P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof.
```

Le choix de P5-01 avant New Game est volontaire : le repo possède déjà un
builder pur `createNewGameState`, mais la preuve "projet créé/sauvé par
l'éditeur -> disque -> runtime host" reste le dernier prérequis de contexte
avant de connecter un New Game minimal à un vrai chemin de lancement.

## 2. Scope du lot

Inclus :

```text
audit documentaire et gouvernance
lecture des roadmaps et rapports bêta
inspection ciblée du code gameplay/runtime/editor
critique de la roadmap Phase 5 actuelle
recalibration de MVP Selbrume/road_map_phase_5.md
création du rapport P5-00
```

Exclus et non exécutés :

```text
code de production
tests
fixtures
New Game implementation
starter flow
XP / rewards / money apply
heal center
capture / box
UI
Boot Flow complet
P5-01
```

## 3. Sources lues

Fichiers de gouvernance :

```text
AGENTS.md
skills/README.md
MVP Selbrume/road_map_global.md
MVP Selbrume/road_map_phase_5.md
reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md
MVP Selbrume/checklist_beta_pokemap.md
reports/beta/beta_readiness_audit.md
reports/beta/beta_roadmap_to_functional_beta.md
pokemap_roadmap_mecaniques_fangame.md
```

Fichiers gameplay/runtime/editor inspectés :

```text
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/lib/src/player_spawn_resolver.dart
packages/map_gameplay/lib/src/game_state_mutations.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
packages/map_gameplay/test/give_pokemon_test.dart
packages/map_gameplay/test/game_state_mutations_test.dart
packages/map_core/lib/src/models/game_state.dart
packages/map_core/lib/src/models/save_data.dart
packages/map_core/lib/src/operations/game_state_persistence.dart
packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
packages/map_runtime/lib/src/infrastructure/file_game_save_repository.dart
packages/map_runtime/lib/src/application/save_game_use_case.dart
packages/map_runtime/lib/src/application/load_game_use_case.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/test/reward_bridge_readiness_test.dart
examples/playable_runtime_host/lib/src/runtime_launch_save.dart
examples/playable_runtime_host/lib/main.dart
```

Fichiers absents documentés :

```text
beta_readiness_audit.md : absent à la racine
beta_roadmap_to_functional_beta.md : absent à la racine
Pasted markdown.md : absent dans le repo
```

`Pasted markdown.md` reste traité comme contexte utilisateur externe sur une
vision future du Boot Flow complet, pas comme scope immédiat Phase 5.

## 4. Diagnostic de la roadmap Phase 5 actuelle

Analyse lot par lot de la roadmap initiale :

| Lot initial | Diagnostic | Décision |
|---|---|---|
| P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit | Audit légitime, mais doit être critique et recalibrant. | Conservé et renommé en recalibration. |
| P5-01 — New Game / Initial GameState Contract Review | Trop documentaire. Le repo a déjà un builder pur partiel ; le prochain besoin est une preuve, pas une review. | Remplacé par P5-01 disk smoke, puis New Game Builder V0 en P5-02. |
| P5-02 — Starter / Initial Party Minimal Flow | Bonne cible mais doit produire une opération/test, pas une intention. | Conservé comme P5-03 V0 concret. |
| P5-03 — Runtime Party Menu Minimal Read Model | Risque UI/read-model prématuré si isolé. La bêta a surtout besoin d'opérations party/bag/heal prouvées. | Fusionné dans P5-04 Party / Bag / Heal Minimal Operations V0. |
| P5-04 — Bag / Item Use Runtime Minimal Contract | Trop "contract". Le bag existe partiellement ; il faut prouver l'usage minimal hors combat. | Fusionné dans P5-04 avec party/heal. |
| P5-05 — Heal Center Minimal Flow | Bonne cible, mais elle dépend de party/bag/medicine. | Fusionné dans P5-04. |
| P5-06 — Battle Rewards / Money / XP Minimal Contract | Trop "contract". Le pont reward item narratif existe, mais rewards/money/XP gameplay restent à appliquer. | Conservé comme P5-05 Apply V0 concret. |
| P5-07 — Capture Destination / Party-or-Box Decision | Trop "decision". Le runtime capture vers party et échoue si party pleine ; il faut une destination testée. | Conservé comme P5-06 Party-or-Box V0. |
| P5-08 — Gameplay Save/Load Beta Roundtrip | Bonne preuve, mais doit inclure les états ajoutés par P5-02 à P5-06. | Conservé comme P5-07 V0 concret. |
| P5-09 — Beta Playability Validator Plan | Trop "plan". Doit devenir un validator V0 avec diagnostics. | Conservé comme P5-09 Beta Playability Validator V0. |
| P5-CHECKPOINT-01 | Nécessaire. | Conservé. |

Conclusion :

```text
Oui, la roadmap Phase 5 actuelle était trop documentaire.
À partir de P5-01, chaque lot doit produire une preuve gameplay concrète.
```

## 5. New Game minimal vs Boot Flow complet

Décision explicite :

```text
Le New Game Phase 5 doit rester ultra minimal.
Le Boot Flow complet est reporté.
```

New Game V0 doit viser :

```text
GameState initial valide
map de départ
spawn / position initiale
facing initial
party initiale vide ou configurée
bag initial
money initial
flags / steps initiaux si disponibles
lancement runtime ou test runtime depuis cet état
```

Boot Flow complet hors scope immédiat :

```text
vidéo d'intro
écran titre
"Appuie sur Start"
écran de sauvegardes
Continue / Nouvelle partie complet
cinématique d'ouverture
handoff UX premium
transitions fancy
```

Décision de report :

```text
Vision produit intéressante, mais hors scope immédiat P5.
À reporter après New Game minimal, probablement Phase 7 ou chantier dédié
"Expérience de lancement du jeu".
```

## 6. État réel de la boucle RPG minimale

### Runtime project disk loading / boot minimal

Observé :

```text
FileProjectRepository peut sauvegarder/charger un ProjectManifest JSON.
loadRuntimeMapBundle existe côté runtime.
playable_runtime_host charge un project.json et une launch save technique.
P3-07 a prouvé un host smoke minimal, mais avec fixture technique dédiée.
```

Limite :

```text
La preuve "projet créé/sauvé par l'éditeur -> project.json -> runtime host"
n'est pas encore isolée comme preuve gameplay bêta.
Le host dépend encore d'une launch save ou d'un seed demo dans plusieurs chemins.
```

Décision :

```text
P5-01 doit précéder New Game.
```

### New Game ultra minimal

Observé :

```text
packages/map_gameplay/lib/src/new_game_state_builder.dart expose createNewGameState.
Il initialise saveId, currentMapId, playerPosition, playerFacing, movement,
party vide, bag vide, progression vide, flags/events vides, metadata vide,
trainerProfile name et money=0.
```

Tests observés :

```text
packages/map_gameplay/test/new_game_state_builder_test.dart couvre la création,
le trim, facing, position, empty party/bag/progression, save/load roundtrip
et l'absence d'IDs Selbrume hardcodés.
```

Limite :

```text
Le builder n'est pas encore connecté au manifest, au spawn resolver, au runtime
host, à une initial party/starter, ni à une preuve disque/runtime P5.
```

### Starter / initial party

Observé :

```text
GameStateMutations.givePokemon existe.
PlayerPokemon existe avec speciesId, natureId, abilityId, level, moves, HP,
status, heldItem.
give_pokemon_test couvre ajout, déduplication optionnelle et roundtrip save/load.
```

Limite :

```text
Il n'existe pas encore de starter flow minimal relié à une configuration projet.
Le modèle PlayerPokemon ne porte pas d'expérience courante ; XP/level-up restent
hors preuve.
```

### Party / bag / heal

Observé :

```text
Bag, BagEntry et TrainerProfile.money existent dans SaveData.
GameStateMutations.giveItem existe et catégorise notamment potion comme medicine.
Des objets de soin existent en combat runtime via runtime_battle_bag_hp_heal_item_apply.dart.
```

Limite :

```text
Le soin hors combat / healParty / heal center minimal n'est pas prouvé.
Le runtime bag menu hors combat n'est pas une preuve bêta complète.
```

### Battle rewards / money / XP

Observé :

```text
runtime_battle_outcome_apply.dart applique HP write-back, trainer defeated,
capture vers party et consommation d'une poke-ball.
reward_bridge_readiness_test prouve une continuation narrative post-victoire
qui peut donner un item et poser fact/step.
TrainerProfile.money est persisté.
```

Limite :

```text
Le test reward bridge précise que l'item reward n'implique pas money, XP ou
level-up. Il ne prouve pas une récompense gameplay complète.
XP courant, distribution XP et level-up apply restent non prouvés.
```

### Capture destination party-or-box

Observé :

```text
Le runtime peut ajouter un Pokémon capturé à la party et consommer une poke-ball.
La progression seen/caught est mise à jour dans ce chemin.
```

Limite :

```text
Si la party est pleine, runtime_battle_outcome_apply.dart échoue explicitement.
Il n'y a pas encore de destination party-or-box ou storage minimal prouvé.
```

### Save/load gameplay beta

Observé :

```text
FileGameSaveRepository, SaveGameUseCase et LoadGameUseCase existent.
P3-06 a prouvé save/load narratif.
Des tests map_gameplay prouvent roundtrip de New Game, starter donné et items.
```

Limite :

```text
Le roundtrip bêta complet après combat, capture, rewards, XP, money, heal et
runtime save menu n'est pas encore prouvé.
```

### Beta playability validator

Observé :

```text
ProjectValidator et MapValidator existent.
Narrative validator Phase 2/4 existe.
Le map validator contrôle déjà certains spawns/defaultSpawnId.
```

Limite :

```text
Il n'existe pas encore de validator unique "ce projet peut être lancé et joué
en bêta minimale".
```

## 7. Audit par bloc gameplay

Constats synthétiques :

```text
Modèles existants : GameState, SaveData, PlayerPokemon, PlayerParty, Bag,
TrainerProfile, progression, trainers, encounters.

Tests purs existants : New Game builder partiel, givePokemon, giveItem,
save/load local, narrative authoring, runtime narrative.

Runtime câblé : PlayableMapGame, runtime host, battle handoff/write-back,
save/load use cases, launch save/demo seed.

UI existante : host et menus runtime partiels, mais pas preuve UI premium ni
workflow New Game final.

Persistence réelle : project.json et save file existent, mais pas encore le
roundtrip gameplay bêta complet.

Preuve end-to-end : absente pour une boucle New Game -> battle -> reward ->
save/load sur projet éditeur.
```

## 8. Matrice des gaps bêta

| Bloc | État actuel | Preuve / fichiers observés | Niveau de preuve | Bloquant bêta ? | Risque documentaire | Lot Phase 5 recommandé | Décision |
|---|---|---|---|---|---|---|---|
| Editor-created project disk smoke | Partiel | `FileProjectRepository`, `loadRuntimeMapBundle`, P3-07 fixture host | Modèle + disque technique, pas éditeur->runtime | Oui | Moyen si reporté | P5-01 | Faire en premier |
| New Game minimal | Partiel | `createNewGameState`, tests map_gameplay | Test pur | Oui | Fort si "Contract Review" | P5-02 | Builder V0 concret |
| Initial GameState builder | Partiel solide | `new_game_state_builder.dart` | Test pur | Oui | Moyen | P5-02 | Étendre/relier au manifest/spawn |
| Starter / initial party | Partiel | `givePokemon`, `PlayerPokemon`, tests | Test pur | Oui | Faible si opération | P5-03 | Flow minimal |
| Initial bag / money / flags | Partiel | `giveItem`, `TrainerProfile.money`, flags/progression | Test pur fragmenté | Oui | Moyen | P5-02/P5-03 | Initialiser explicitement |
| Start map / spawn validation | Partiel | `player_spawn_resolver.dart`, validators spawn | Modèle + tests locaux | Oui | Moyen | P5-01/P5-02/P5-09 | Relier disque/runtime |
| Runtime party menu | Partiel | menus/runtime references, battle setup mapper | Runtime partiel | Oui pour bêta ergonomique | Moyen | P5-04 | Ne pas faire UI premium |
| PlayerPokemon persistence | Partiel | `SaveData`, tests roundtrip | Test pur | Oui | Faible | P5-07 | Roundtrip bêta |
| Bag model | Partiel solide | `Bag`, `BagEntry`, `giveItem` | Modèle + test pur | Oui | Faible | P5-04 | Operations hors combat |
| Runtime bag menu | Partiel | battle bag HP heal, runtime menu traces | Runtime partiel | Oui | Moyen | P5-04 | Minimal seulement |
| Medicine outside battle | Absent/partiel | healing items battle only | Runtime battle, pas overworld | Oui | Faible | P5-04 | Ajouter opération V0 |
| Heal center | Absent | aucun `healParty` stable observé | Absent | Oui | Faible | P5-04 | Operation V0 |
| Battle write-back | Partiel | `runtime_battle_outcome_apply.dart` | Runtime testable | Oui | Faible | P5-05 | Maintenir et compléter |
| Trainer defeated policy | Partiel | `StoryFlagsManager`, runtime outcome apply | Runtime partiel | Oui | Faible | P5-05/P5-08 | Stabiliser policy |
| Battle rewards | Partiel narratif | `reward_bridge_readiness_test` item/fact/step | Runtime/narrative fragment | Oui | Fort si "Contract" | P5-05 | Apply V0 concret |
| Money | Modèle présent, apply absent | `TrainerProfile.money`, reward bridge conserve money | Modèle + persistence | Oui | Moyen | P5-05 | Appliquer gain minimal |
| XP distribution | Absent | pas de champ XP courant dans `PlayerPokemon` | Absent | Oui | Moyen | P5-05 | Décision + apply minimal |
| Level-up apply | Absent/limité | level existe, XP absent | Modèle partiel | Oui | Moyen | P5-05 | Minimal si supportable |
| Capture formula | Partiel | wild capture outcome runtime | Runtime partiel | Moyen | Faible | P5-06 | Peut rester simple |
| Capture destination party/box | Partiel | party capture, party full throw | Runtime partiel | Oui | Fort si "Decision" | P5-06 | Party-or-box V0 |
| PC / box storage | Absent | aucun storage minimal prouvé | Absent | Oui si party full capture | Moyen | P5-06 | Storage minimal sans UI |
| Wild encounter loop | Partiel | encounter models/runtime requests | Runtime partiel | Oui | Moyen | P5-08 | Smoke beta |
| Trainer battle loop | Partiel | trainer battle request, battle setup/write-back | Runtime partiel | Oui | Faible | P5-08 | Smoke beta |
| Runtime save/load | Partiel | `FileGameSaveRepository`, use cases, PlayableMapGame save/load | Runtime/persistence partiel | Oui | Faible | P5-07 | Roundtrip beta |
| Runtime save menu | Partiel | `PlayableMapGame.saveGame/loadGame`, host menu traces | Runtime partiel | Moyen | Moyen | P5-07/P5-08 | Minimal seulement |
| Beta playability validator | Absent | validators dispersés | Absent | Oui | Fort si "Plan" | P5-09 | Validator V0 |
| Selbrume golden slice readiness | Non prêt | beta audits | Rapport seulement | Non pour P5 immédiat | Fort | Phase 6 | Reporter |
| Audio minimal | Partiel/absent côté preuve bêta | beta checklist/audit le signale | Gap bêta | Moyen | Moyen | P5-10 | Preuve minimale, pas polish |
| Boot Flow / Launch Experience | Hors scope immédiat | contexte utilisateur, `Pasted markdown.md` absent | Vision produit, pas preuve P5 | Non pour New Game V0 | Fort | Phase 7 / chantier dédié | Reporter explicitement |

## 9. Risques de dérive documentaire

Risques identifiés :

```text
P5-01 "Contract Review" pouvait redécrire createNewGameState sans relier runtime/disque.
P5-04 "Minimal Contract" pouvait éviter l'usage réel du bag hors combat.
P5-07 "Decision" pouvait ne pas résoudre le cas party pleine.
P5-09 "Plan" pouvait repousser le validator sans preuve.
```

Règle Phase 5 après P5-00 :

```text
Chaque lot P5-01 à P5-10 doit produire au moins une preuve exécutable ou un
blocage technique irréprochable. Les documents seuls ne suffisent plus.
```

## 10. Roadmap Phase 5 recalibrée

Roadmap retenue :

```text
P5-00 — Phase 5 Roadmap Recalibration / Gameplay Loop Audit
P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof
P5-02 — New Game / Initial GameState Builder V0
P5-03 — Starter / Initial Party Minimal Flow V0
P5-04 — Party / Bag / Heal Minimal Operations V0
P5-05 — Battle Rewards / Money / XP Minimal Apply V0
P5-06 — Capture Destination Party-or-Box V0
P5-07 — Gameplay Save/Load Beta Roundtrip V0
P5-08 — Beta Runtime Smoke : New Game -> Battle -> Reward -> Save/Load
P5-09 — Beta Playability Validator V0
P5-10 — Audio Minimal Runtime Proof V0
P5-CHECKPOINT-01 — Gameplay Loop Readiness Review
```

Justification de P5-01 :

```text
Le chemin runtime/disk Phase 3 a été prouvé sur fixtures techniques.
Avant de créer ou brancher un New Game minimal, il faut prouver que le runtime
peut consommer un projet disque issu du chemin éditeur, ou documenter le gap.
```

Pourquoi P5-10 audio est ajouté :

```text
Les audits bêta existants signalent l'audio minimal comme gap de bêta.
Il reste après la boucle gameplay principale pour éviter de voler la priorité
aux preuves New Game / battle / rewards / save-load.
```

## 11. Prochain lot exact

Prochain lot exact :

```text
P5-01 — Runtime Project Disk Smoke / Editor-created Project Proof
```

Raison :

```text
Le repo possède déjà des briques New Game pures, mais pas encore la preuve
éditeur -> disque -> runtime host nécessaire pour éviter de brancher un New Game
sur une fixture trop artificielle.
```

## 12. Modifications effectuées

Fichier créé :

```text
reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
```

Fichier modifié :

```text
MVP Selbrume/road_map_phase_5.md
```

Fichiers volontairement non modifiés :

```text
MVP Selbrume/road_map_global.md
packages/**
examples/**
tests
fixtures
```

## 13. Evidence Pack

### git status initial exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
```

### Empreinte initiale road_map_global.md

Commande :

```bash
shasum "MVP Selbrume/road_map_global.md"
```

Sortie :

```text
239af952087c425457ddb308822ea356b5e7dce9  MVP Selbrume/road_map_global.md
```

### Commandes exécutées

```bash
git status --short --untracked-files=all
shasum "MVP Selbrume/road_map_global.md"
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,760p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_4/p4_checkpoint_01_authoring_workflow_readiness_review.md
sed -n '1,220p' skills/README.md || true
sed -n '1,260p' AGENTS.md
for f in MVP\ Selbrume/checklist_beta_pokemap.md reports/beta/beta_readiness_audit.md reports/beta/beta_roadmap_to_functional_beta.md beta_readiness_audit.md beta_roadmap_to_functional_beta.md pokemap_roadmap_mecaniques_fangame.md "Pasted markdown.md"; do echo "===== $f ====="; test -f "$f" && sed -n '1,260p' "$f" || echo "ABSENT"; done
rg -n "New Game|createNewGameState|initial|starter|givePokemon|party|PlayerPokemon|bag|money|wallet|item use|medicine|heal|healParty|Pokemon Center|PC|Box|capture|caught|battle reward|reward|XP|experience|level-up|trainer defeated|save|load|runtime save|encounter|wild battle|trainer battle|playable_runtime_host|boot flow|launch|title screen|intro" packages examples "MVP Selbrume" reports --glob '!build/**' --glob '!**/.dart_tool/**'
find reports/roadmap -maxdepth 3 -type f | sort | rg "phase_5|beta|gameplay|fangame|roadmap"
find packages/map_core/lib/src -maxdepth 3 -type f | sort | rg "game_state|save_data|pokemon|party|bag|item|trainer|battle|encounter|progression"
find packages/map_gameplay/lib -type f | sort
find packages/map_runtime/lib -type f | sort | rg "battle|save|runtime|game|encounter|bag|party|new|heal|starter|launch|boot"
find packages/map_battle/lib -type f | sort | head -200
rg -n "class .*Project.*Repository|saveProject\\(|loadProject\\(|ProjectRepository|saveProjectManifest|ProjectManifest" packages/map_editor/lib packages/map_core/lib --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "class Bag|class TrainerProfile|class PlayerPokemon|experience|xp|level|money|BagEntry|PlayerParty|PlayerProgression|caught|seen" packages/map_core/lib/src/models/save_data.dart packages/map_core/lib/src/models/game_state.dart
rg -n "healParty|heal|Potion|medicine|Bag|bag|party|starter|givePokemon|giveItem|createNewGameState|resolveInitialPlayerSpawn" packages/map_gameplay/lib packages/map_runtime/lib packages/map_core/test packages/map_gameplay/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,140p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '90,370p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,280p' packages/map_gameplay/test/new_game_state_builder_test.dart
sed -n '1,280p' packages/map_gameplay/test/give_pokemon_test.dart
sed -n '1,260p' packages/map_gameplay/test/game_state_mutations_test.dart
rg -n "class FileGameSaveRepository|SaveGameUseCase|LoadGameUseCase|GameSaveRepository|saveGame|loadGame" packages/map_runtime/lib packages/map_runtime/test examples/playable_runtime_host/test --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "Playability|playability|validator|spawn|encounter|trainer|starter|project can be launched|can be launched|Beta" packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor/test packages/map_core/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,260p' packages/map_runtime/test/reward_bridge_readiness_test.dart
rg -n "money|reward|experience|XP|xp|level|giveItem|trainerProfile" packages/map_runtime/lib/src/application packages/map_gameplay/lib/src packages/map_battle/lib/src --glob '!build/**' --glob '!**/.dart_tool/**'
mkdir -p reports/roadmap/phase_5
git diff --check
git diff --stat
git diff --name-only
git status --short --untracked-files=all
git diff --name-only -- "MVP Selbrume/road_map_global.md"
git diff --name-only -- packages examples
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle
rg -n "PENDING_FINAL|P5-01 — Runtime Project Disk Smoke|P5-00 : terminé|Boot Flow complet" "MVP Selbrume/road_map_phase_5.md" reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
```

### Sorties utiles

`road_map_global.md` :

```text
Phase courante : Phase 5 — Gameplay Gaps Prioritaires
Roadmap de phase courante : MVP Selbrume/road_map_phase_5.md
Lot courant / prochain lot : P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
Phase 4 — Authoring Workflows Minimal : ✅ clôturée avec réserves mineures
```

`road_map_phase_5.md` avant modification :

```text
P5-00 — Phase 5 Roadmap Bootstrap / Gameplay Loop Audit
P5-01 — New Game / Initial GameState Contract Review
P5-04 — Bag / Item Use Runtime Minimal Contract
P5-07 — Capture Destination / Party-or-Box Decision
P5-09 — Beta Playability Validator Plan
```

Rapports bêta :

```text
PokeMap n'est pas beta-ready.
Les gaps signalés incluent New Game runtime, starter, party menu, bag runtime,
heal, battle rewards, money, XP, capture destination, save/load bêta, validator,
audio minimal et Selbrume non assemblé.
```

`pokemap_roadmap_mecaniques_fangame.md` :

```text
Les lots gameplay restent TODO/PARTIAL sans preuve fraîche.
Ne pas marquer DONE sans fichiers modifiés, commandes, résultats exacts et limites.
```

`Pasted markdown.md` :

```text
ABSENT
```

Code gameplay observé :

```text
createNewGameState existe et initialise un GameState minimal.
resolveInitialPlayerSpawn existe.
GameStateMutations.givePokemon et giveItem existent.
PlayerPokemon / PlayerParty / Bag / TrainerProfile.money existent.
XP courant et level-up apply ne sont pas prouvés dans PlayerPokemon.
runtime_battle_outcome_apply applique HP write-back, trainer defeated, capture
vers party et consommation d'une poke-ball, mais échoue si party pleine.
reward_bridge_readiness_test prouve item/fact/step post-victoire via continuation
narrative, pas money/XP/level-up.
```

Commandes `rg` très longues :

```text
Les sorties ont été synthétisées ci-dessus pour conserver les signaux utiles.
Les chemins significatifs trouvés incluent map_gameplay new_game/givePokemon/giveItem,
map_runtime battle outcome apply/save/load/runtime host, map_core SaveData/GameState,
map_editor FileProjectRepository, et les rapports beta/roadmaps.
```

### Tests exécutés

Aucun test n'a été lancé.

Justification :

```text
P5-00 est un audit documentaire.
Le contrat demandait de ne pas lancer de tests sauf raison précise.
Les preuves de tests existantes ont été lues dans les fichiers et rapports.
```

### Fichiers créés

```text
reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
```

### Fichiers modifiés

```text
MVP Selbrume/road_map_phase_5.md
```

### git diff --check exact

Commande :

```bash
git diff --check
```

Sortie exacte :

```text
```

### git diff --stat exact

Commande :

```bash
git diff --stat
```

Sortie exacte :

```text
 MVP Selbrume/road_map_phase_5.md | 459 ++++++++++++++++++++++++---------------
 1 file changed, 281 insertions(+), 178 deletions(-)
```

### git diff --name-only exact

Commande :

```bash
git diff --name-only
```

Sortie exacte :

```text
MVP Selbrume/road_map_phase_5.md
```

### git status final exact

Commande :

```bash
git status --short --untracked-files=all
```

Sortie exacte :

```text
 M "MVP Selbrume/road_map_phase_5.md"
?? reports/roadmap/phase_5/p5_00_phase_5_roadmap_recalibration_gameplay_loop_audit.md
```

### Empreinte finale road_map_global.md

Commande :

```bash
shasum "MVP Selbrume/road_map_global.md"
```

Sortie :

```text
239af952087c425457ddb308822ea356b5e7dce9  MVP Selbrume/road_map_global.md
```

### Contrôles explicites hors scope

Commande :

```bash
git diff --name-only -- "MVP Selbrume/road_map_global.md"
```

Sortie exacte :

```text
```

Commande :

```bash
git diff --name-only -- packages examples
```

Sortie exacte :

```text
```

Commande :

```bash
git diff --name-only -- packages/map_core packages/map_gameplay packages/map_runtime packages/map_editor packages/map_battle
```

Sortie exacte :

```text
```

```text
Aucun code n'a été modifié.
Aucun test n'a été modifié.
MVP Selbrume/road_map_global.md n'a pas été modifié.
P5-01 n'a pas été exécuté.
Selbrume final n'a pas été créé.
Aucune UI premium n'a été créée.
Aucun Boot Flow complet n'a été ajouté au scope P5 immédiat.
Aucun reward/money/XP n'a été ajouté en code.
```

## 14. Auto-review critique

Points forts :

```text
La roadmap n'est pas acceptée par inertie.
Le risque documentaire est explicite.
Le New Game est recadré en V0 minimal.
Le Boot Flow complet est reporté.
Le prochain lot exact est fixé.
```

Réserves :

```text
P5-00 ne prouve aucun nouveau comportement exécutable, volontairement.
Plusieurs constats sont des signaux d'audit issus de recherches longues, pas des
tests relancés.
Le statut beta-ready reste négatif tant que P5-01 à P5-09/P5-10 ne produisent
pas leurs preuves.
```

## 15. Regard critique sur le prompt

Le prompt est utile parce qu'il force le recadrage New Game minimal vs Boot Flow
complet. C'est important : sans cette contrainte, la Phase 5 pourrait dériver
vers une expérience de lancement séduisante mais trop tôt, alors que la vraie
priorité est la boucle RPG minimale prouvable.

La recommandation par défaut `P5-01 — Runtime Project Disk Smoke / Editor-created
Project Proof` est confirmée : elle réduit le risque de construire New Game sur
une fixture trop artificielle.
