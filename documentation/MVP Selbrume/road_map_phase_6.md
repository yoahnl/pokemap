# Phase 6 Roadmap — Selbrume Golden Slice réel

## Statut de la phase

Phase 6 ouverte par le checkpoint Phase 5.

Statut : ✅ clôturée avec réserves mineures

SELBRUME_EXISTING_PROJECT_PATH :

```text
/Users/karim/Project/pokemonProject/selbrume
```

Ancien chemin historique :

```text
/Users/karim/Desktop/selbrume
```

Lot courant : ✅ P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

Prochain lot exact : P7-00 — Phase 7 Roadmap Bootstrap / Modern UI Scope Audit

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
- ✅ P6-01 — Existing Selbrume Loadability / Start Map Contract V0
- ✅ P6-02 — Selbrume Initial Party / Bag Setup V0
- ✅ P6-03 — Selbrume First Narrative Interaction V0
- ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0
- ✅ P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup
- ✅ P6-04-ter — Selbrume Grant Reconciliation / P6-03 Regression Fix
- ✅ P6-05 — Selbrume First Trainer Battle Golden Slice V0
- ✅ P6-06 — Selbrume Save/Load Golden Slice V0
- ✅ P6-07 — Selbrume Beta Validator Pass V0
- ✅ P6-08 — Selbrume Playable Runtime Smoke V0
- ✅ P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

P6-00 : ✅ terminé

P6-01 : ✅ terminé

P6-02 : ✅ terminé

P6-03 : ✅ terminé

P6-04 : ✅ terminé

P6-04-bis : ✅ terminé

P6-04-ter : ✅ terminé

P6-05 : ✅ terminé

P6-06 : ✅ terminé

P6-07 : ✅ terminé

P6-08 : ✅ terminé

P6-CHECKPOINT-01 : ✅ terminé

Prochain lot exact :

```text
P7-00 — Phase 7 Roadmap Bootstrap / Modern UI Scope Audit
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
-> route 1 encounter / capture minimale
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

## Changement de chemin actif P6-01

Après P6-00, le projet Selbrume a été intégré directement dans le repo Git.

Chemin actif Phase 6 :

```text
/Users/karim/Project/pokemonProject/selbrume
```

L'ancien chemin Desktop reste une information historique du checkpoint bis et
de l'audit P6-00. Les preuves actives P6-01 et suivantes doivent utiliser le
dossier repo-local `selbrume/`.

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

## Résultat P6-01

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json existe
loadRuntimeMapBundle charge explicitement la map Selbrume
loadRuntimeMapBundle charge explicitement la map route 1
la première map du manifest reste route 1
le contrat de départ ne dépend donc pas de la première map déclarée
start map retenue : Selbrume
spawn retenu : spawn
position attendue : x=17, y=24
facing attendu : south
createNewGameStateFromMap construit un GameState initial depuis Selbrume/spawn
```

Décision `defaultSpawnId` :

```text
Selbrume.mapMetadata.defaultSpawnId reste null dans les données existantes.
P6-01 ne modifie pas les données Selbrume, car le dossier selbrume/ était déjà
massivement ajouté à l'état Git au Gate 0. Le contrat P6-01 est donc prouvé par
sélection explicite startMapId=Selbrume et spawnId=spawn dans le test.
```

## Résultat P6-02

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
start map retenue : Selbrume
spawn retenu : spawn
position conservée : x=17, y=24
facing conservé : south
party initiale seedée par test : pidgeotto niveau 8
moves retenus : gust, tackle
bag initial seedé par test : poke-ball x5, potion x2
money initial conservé : 0
roundtrip SaveData conserve map, position, facing, party, bag, money, caught/seen
```

Décision initial party / bag :

```text
aucun champ officiel initialParty ou initialBag n'existe dans ProjectManifest
aucun contrat New Game config persistant n'est créé en P6-02
aucun fichier selbrume/ n'est modifié
le setup initial est prouvé par seed explicite de test
```

## Résultat P6-03

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
start map retenue : Selbrume
spawn retenu : spawn
party/bag minimal seedé comme P6-02
interaction retenue : p6_03_intro_sign
scénario retenu : p6_03_first_interaction
preuve : ScenarioRuntimeExecutor.dispatch(entityInteract)
effet runtime observable : showMessage court
effet persistable : story flag p6.selbrume.first_interaction.seen
effet persistable : completed step p6.selbrume.first_interaction
roundtrip SaveData conserve flag, completed step, party et bag
```

Fichiers Selbrume modifiés :

```text
selbrume/project.json
selbrume/maps/Selbrume.json
```

Décision narrative :

```text
l'interaction est une preuve technique golden slice V0
elle n'est pas un dialogue final, une quête finale, un PNJ final ou une cinématique
aucun combat, reward, capture ou P6-04 n'est démarré en P6-03
```

## Résultat P6-04

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées : Selbrume et route 1
connexion observée : route 1 -> Selbrume
encounter table retenue : grass_path_route_1
encounter kind : walk
zones route 1 exploitables : 5 zones encounter
species encounter/capture : pidgeotto
plage de niveau authorée : 1..5
niveau déclenché dans le test : 3
moves vérifiés : gust, tackle
item capture vérifié : poke-ball
bag initial P6-02 : poke-ball x5, potion x2
preuve encounter : gameplay encounter via checkEncounterAtPlayerPosition
preuve runtime-application : WildBattleStartRequest via buildBattleStartRequestFromEncounter
capture minimale : applyCapturedPokemon
destination capture : party
bag après capture : poke-ball x4, potion x2
roundtrip SaveData conserve route 1, party, capture, bag, seen/caught et flags P6-03
```

Décision encounter / capture :

```text
aucun fichier selbrume/ n'est modifié en P6-04
la table existante grass_path_route_1 est réutilisée
la preuve ne lance pas Battle UI et ne crée pas de trainer battle
le pidgeotto capturé duplique volontairement l'espèce initiale P6-02, car la table Route 1 ne contient que pidgeotto
```

## Résultat P6-04-bis

Décision : option B.

P6-04-bis a établi que les changements `grant` ne sont plus des diffs courants :
ils sont désormais suivis par Git.

Attribution historique :

```text
02fbb1db -> ajout de selbrume/assets/tilesets/grant.png
cbfec67e -> ajout de grant dans project.json, ajout de l'entité grant sur route 1,
             ajout des artefacts P6-04 et retrait du scénario P6-03 dans project.json
```

Impact vérifié :

```text
P6-04 passe encore.
P6-02 passe encore.
P6-01 échoue car route 1 n'est plus vide.
P6-03 échoue car p6_03_first_interaction est absent de project.json.
```

Décision roadmap :

```text
Ne pas passer directement à P6-05.
Le prochain lot exact devient P6-04-ter — Selbrume Grant Diff Attribution / P6-03 Regression Fix.
```

## Résultat P6-04-ter

Grant est confirmé comme contenu utilisateur volontaire fourni par Karim.
P6-04-ter le conserve et ne modifie pas son trainer, son NPC, son character ou
son asset.

Corrections réalisées :

```text
p6_03_first_interaction restauré dans selbrume/project.json
P6-01 adapté à route 1 contenant désormais l'entité NPC grant
P6-02, P6-03 et P6-04 relancés sans régression
```

Décision roadmap :

```text
Les preuves P6-01/P6-02/P6-03/P6-04 repassent.
P6-05 peut démarrer explicitement sur Grant ou sur un autre trainer choisi.
Prochain lot exact : P6-05 — Selbrume First Trainer Battle Golden Slice V0.
```

## Résultat P6-05

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées : Selbrume et route 1
trainer retenu : grant
NPC route 1 retenu : grant avec trainerId=grant
asset Grant conservé : assets/tilesets/grant.png
team Grant vérifiée : bulbasaur niveau 1, metapod niveau 25, ivysaur niveau 25
moves Grant vérifiés : growl, tackle, harden, sweet_scent, growth, leech_seed
état golden slice seedé : party/bag P6-02, flag/step P6-03, capture P6-04 conservée
position route 1 testée : x=24, y=22, facing north
TrainerBattleStartRequest construit depuis l'entité NPC Grant
RuntimeBattleSetupMapper construit un BattleSetup trainer Grant
createBattleSession démarre une session battle non terminée avec Grant
outcome victoire contrôlé appliqué via applyRuntimeBattleOutcomeToGameState
trainer defeated flag : trainer_defeated:grant
reward minimal test-level : money +120, level-up direct party[0] +1
roundtrip SaveData conserve route 1, party, bag, capture, flags, money et level-up
```

Niveau de preuve battle :

```text
runtime-application trainer battle setup + controlled victory outcome write-back
pas de victoire battle engine complète
pas de Battle UI
pas de reward UI
```

Décision roadmap :

```text
P6-05 est concluant.
Grant reste conservé comme contenu utilisateur volontaire.
Aucun code production et aucun fichier selbrume/ n'est modifié en P6-05.
Prochain lot exact : P6-06 — Selbrume Save/Load Golden Slice V0.
```

## Résultat P6-06

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées : Selbrume et route 1
état golden slice reconstruit depuis les preuves P6-02 à P6-05
party : pidgeotto niveau 9, pidgeotto capturé niveau 3
bag : poke-ball x4, potion x2
progression narrative : p6.selbrume.first_interaction.seen
completed step : p6.selbrume.first_interaction
trainer defeated flag : trainer_defeated:grant
money : 120
position finale : route 1, x=24, y=22, facing north
repository : SaveGameUseCase + LoadGameUseCase + FileGameSaveRepository
fichier disque temporaire hors repo : Directory.systemTemp sous p6_06_selbrume_save_load_*/pokemonProject/game_save.json
rechargement disque réel prouvé
normalizeLoadedGameState appliqué après LoadGameUseCase
assertions golden slice complètes après reload
```

Niveau de preuve save/load :

```text
repository/use-case disque réel
pas seulement un roundtrip SaveData en mémoire
pas de UI save/load
pas de Boot Flow
```

Décision roadmap :

```text
P6-06 est concluant.
Aucun code production et aucun fichier selbrume/ n'est modifié en P6-06.
Prochain lot exact : P6-07 — Selbrume Beta Validator Pass V0.
```

## Résultat P6-07

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées explicitement : Selbrume et route 1
les 10 maps déclarées sont fournies au validator via mapsById
startMapId validator : Selbrume
spawn joueur : spawn, x=17, y=24, facing south
initial party source : pidgeotto avec moves gust/tackle
capture prerequisite : poke-ball présent dans le catalogue items et seedé par P6-02
encounter Route 1 : grass_path_route_1, kind walk, pidgeotto niveau 1-5
trainer battle prerequisite : NPC grant référence trainer grant
team Grant vérifiée : bulbasaur, metapod, ivysaur
moves Grant vérifiés : growl, tackle, harden, sweet_scent, growth, leech_seed
save/load support : P6-06 prouve SaveGameUseCase + LoadGameUseCase + FileGameSaveRepository
```

Diagnostics validator :

```text
errors : 0
warnings : 0
infos : 0
diagnostics bloquants : aucun
```

Niveau de preuve validator :

```text
validator pass strict : aucun diagnostic bloquant et aucune warning/info
pas de modification du validator
pas de modification selbrume/
pas de runtime smoke complet
```

Décision roadmap :

```text
P6-07 est concluant.
Aucun code production et aucun fichier selbrume/ n'est modifié en P6-07.
Prochain lot exact : P6-08 — Selbrume Playable Runtime Smoke V0.
```

## Résultat P6-08

Preuve ciblée réalisée sur le projet repo-local :

```text
selbrume/project.json est chargé via loadRuntimeMapBundle
maps chargées explicitement : Selbrume et route 1
niveau de smoke obtenu : Level B
API runtime : PlayableMapGame + onLoad + update(0)
état utilisé : New Game Selbrume/spawn seedé avec party/bag P6-02 et flag/step P6-03
map active runtime : Selbrume
position joueur runtime : x=17, y=24
facing : south
flow runtime : overworld
tilesets Selbrume chargés depuis les assets repo-local
aucun crash PlayableMapGame.onLoad
```

Limite honnête :

```text
P6-08 ne lance pas une session joueur interactive complète.
P6-08 n'injecte pas encore l'état sauvegardé complet P6-06 dans route 1.
La preuve est un smoke runtime New Game Selbrume/spawn, pas un Boot Flow.
```

Décision roadmap :

```text
P6-08 est concluant.
Aucun code production et aucun fichier selbrume/ n'est modifié en P6-08.
Prochain lot exact : P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review.
```

## Résultat P6-CHECKPOINT-01

Verdict de clôture :

```text
Phase 6 clôturée avec réserves mineures.
Le golden slice Selbrume minimal est un beta-slice technique validé.
```

Preuves retenues :

```text
projet Selbrume repo-local utilisé comme base active
start map Selbrume / spawn prouvé
party initiale et bag minimal prouvés
première interaction narrative technique prouvée
Route 1 encounter / capture minimale prouvée
trainer battle Grant prouvé au niveau runtime-application
reward minimal money + level-up direct prouvé
save/load disque réel prouvé
validator bêta strict passé
PlayableMapGame smoke Level B passé
```

Réserves explicites :

```text
pas de campagne Selbrume finale
pas d'UI interactive complète
pas de Boot Flow
pas d'écran titre ou slots UI
pas de victoire battle engine complète
pas d'injection de l'état P6-06 complet dans PlayableMapGame
pas de parité Pokémon complète
pas d'audio runtime complet
```

Décision roadmap :

```text
Phase suivante recommandée : Phase 7 — Modern UI / UX Productization.
Prochain lot exact : P7-00 — Phase 7 Roadmap Bootstrap / Modern UI Scope Audit.
P7-00 n'est pas lancé par ce checkpoint.
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

### ✅ P6-01 — Existing Selbrume Loadability / Start Map Contract V0

Statut : terminé.

But :

```text
prouver ou corriger minimalement la charge du projet Selbrume existant et fixer
le contrat de start map / spawn sans créer de contenu final.
```

Preuve :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
```

### ✅ P6-02 — Selbrume Initial Party / Bag Setup V0

Statut : terminé.

But :

```text
fournir une party initiale et un bag minimal utilisables dans le golden slice.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_initial_party_bag_setup_test.dart
```

### ✅ P6-03 — Selbrume First Narrative Interaction V0

Statut : terminé.

But :

```text
prouver une première interaction narrative courte dans le mini-parcours choisi.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

### ✅ P6-04 — Selbrume Route 1 Encounter / Capture Golden Slice V0

Statut : terminé.

But :

```text
prouver une rencontre route 1 bornée et une capture minimale si le bag initial
fournit une source de capture.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_route_1_encounter_capture_golden_slice_test.dart
```

### ✅ P6-04-bis — Selbrume Git Worktree Attribution / Diff Cleanup

Statut : terminé.

But :

```text
attribuer les changements grant observés autour de P6-04 et décider si P6-05
peut démarrer sans mélanger une régression P6 précédente.
```

Décision :

```text
option B : ne pas démarrer P6-05 avant un correctif P6-04-ter.
```

### ✅ P6-04-ter — Selbrume Grant Reconciliation / P6-03 Regression Fix

Statut : terminé.

But :

```text
réconcilier les changements grant avec les contrats P6-01/P6-03 et rétablir les
preuves cassées avant le premier trainer battle.
```

Preuve :

```text
packages/map_runtime/test/p6_existing_selbrume_loadability_start_map_contract_test.dart
packages/map_runtime/test/p6_selbrume_first_narrative_interaction_test.dart
```

### ✅ P6-05 — Selbrume First Trainer Battle Golden Slice V0

Statut : terminé.

But :

```text
prouver un premier trainer battle Selbrume court avec reward minimal.
```

### ✅ P6-06 — Selbrume Save/Load Golden Slice V0

Statut : terminé.

But :

```text
prouver que l'état Selbrume golden slice survit à un vrai save/load disque.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_save_load_golden_slice_test.dart
```

### ✅ P6-07 — Selbrume Beta Validator Pass V0

Statut : terminé.

But :

```text
faire passer le projet Selbrume minimal dans le validator bêta.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_beta_validator_pass_test.dart
```

### ✅ P6-08 — Selbrume Playable Runtime Smoke V0

Statut : terminé.

But :

```text
prouver un smoke runtime jouable court sur le projet Selbrume minimal.
```

Preuve :

```text
packages/map_runtime/test/p6_selbrume_playable_runtime_smoke_test.dart
```

### ✅ P6-CHECKPOINT-01 — Selbrume Beta Slice Readiness Review

Statut : terminé.

But :

```text
déterminer si le golden slice Selbrume minimal est prêt pour la phase suivante.
```

Preuve :

```text
reports/roadmap/phase_6/p6_checkpoint_01_selbrume_beta_slice_readiness_review.md
```

### ➡️ P7-00 — Phase 7 Roadmap Bootstrap / Modern UI Scope Audit

Statut : prochain lot exact hors Phase 6.

But :

```text
auditer le scope UI/UX moderne à partir du beta-slice technique Phase 6 sans
réécrire les fondations ni lancer une refonte cosmétique massive.
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
