# Combat UI + AI Implementation Roadmap

## 1. Resume executif honnete

La trajectoire recommandee n'est pas "IA d'abord" ni "refonte totale de la presentation". Le plus court chemin sain, base sur le repo reel, est :

1. `Lot 1 — Battle Scene UI Pass`
2. `Lot 2 — Contextual Backgrounds`
3. `Lot 3 — BattleOpponentPolicy Seam`
4. `Lot 4 — Difficulty Routing 1..10 -> Internal Profiles`
5. plus tard seulement : scripts trainer/boss et IA plus riche

Le premier lot recommande, noir sur blanc, est **`Battle Scene UI Pass`**. C'est le plus petit lot qui donne un gros gain produit visible sans rouvrir un tunnel battle-core. Il garde `map_battle` stable, travaille la presentation la ou elle vit deja vraiment, et prepare le terrain propre pour les backgrounds dynamiques.

Le deuxieme lot recommande est **`Contextual Backgrounds`**. Le repo a deja suffisamment de contexte runtime pour un resolver simple et honnete. Le faire juste apres la scene est plus rentable que de commencer tout de suite par l'IA, car ce lot reste runtime-only, visible, et peu risquant.

Le troisieme lot recommande est **`BattleOpponentPolicy Seam`**. C'est le plus petit lot architecture qui prepare proprement l'IA sans remettre la difficulte dans `battle_session.dart`. La difficulte `1..10` ne doit venir qu'apres ce seam.

Verdict net :

- UI combat : `do_now`
- separation UI normale / debug : `do_now`
- backgrounds dynamiques : `do_next`
- seam `BattleBackgroundResolver` : `do_next`
- seam `BattleOpponentPolicy` : `do_soon`
- difficulte `1..10` comme API produit : `do_soon`
- profils internes mappes depuis `1..10` : `do_soon`
- scripts trainer/boss : `defer`
- IA avec switch/replacement intelligents : `defer`
- logique IA dans `battle_session.dart` : `not_recommended`

## 2. Pre-gates reellement executes + resultats

Commandes executees exactement :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Resultats observes :

- `git status --short --untracked-files=all`
  - `?? reports/combat-ui-ai-audit-and-roadmap.md`
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - `reports/combat-ui-ai-audit-and-roadmap.md`

Interpretation :

- le repo n'etait pas pristine au debut de ce travail ;
- il n'y avait pas de diff tracked ;
- il y avait deja un report d'audit non tracke ;
- cet etat a ete traite comme baseline de travail, sans reset ni discard.

## 3. Methode reellement suivie

La methode suivie a ete :

1. relancer les pre-gates exacts demandes ;
2. relancer les validations read-only demandees pour confirmer que la baseline battle/runtime/host reste saine ;
3. relire les docs canoniques et l'audit precedent ;
4. relire les seams battle/runtime utiles au sujet UI/backgrounds/IA ;
5. croiser cette lecture avec des sub-agents specialises ;
6. transformer l'audit en une trajectoire unique, lot par lot, avec sequencement et anti-derives explicites ;
7. tenter une review separee finale.

Ce travail est volontairement **read-only**. Aucun code source, test ou asset n'a ete modifie.

Sub-agents consultes :

- `UI/runtime` : confirmation que le premier lot visible le plus rentable est un vrai shell de scene de combat dans `map_runtime`, pas une replomberie battle-core ;
- `battle-core / seam IA` : confirmation que le plus petit seam sain est une `BattleOpponentPolicy` minimale remplaçant la logique de choix ennemi locale, sans ouvrir switch/replacement ;
- `produit / sequencement` : confirmation qu'il faut garder des gains visibles tot et eviter une replongee immediate dans de la plomberie invisible ;
- `backgrounds / contexte map` : audit precedent revalide comme point d'appui, avec conclusion stable : resolver cote runtime, contexte map/trainer/encounter existant, pas de passage par `map_battle`.

## 4. Perimetre du travail

Inclus :

- relire la verite canonique battle apres R2/R3 ;
- relire le seam UI combat actuel dans `map_runtime` ;
- relire les entrees runtime vers combat (`BattleStartRequest`, requests trainer/wild, mapper, move bridge, outcome apply) ;
- relire les points d'entree data utilises pour trainer/map/encounter ;
- relire les points battle-core utiles pour situer le seam IA ;
- relancer les validations demandees ;
- produire une roadmap unique d'implementation, concrete et sequencee.

Exclu :

- toute modification de code ;
- toute modification de tests ;
- toute creation d'asset ;
- tout refactor ;
- toute ouverture de mecanique battle ;
- toute implementation d'IA ;
- toute implementation UI ;
- tout widening request/targeting/replacement.

## 5. Fichiers relus

Docs / reports :

- `/Users/karim/Project/pokemonProject/docs/combat/battle-canonical-state-v3.1.md`
- `/Users/karim/Project/pokemonProject/docs/combat/battle-roadmap-canonical-v3.1.md`
- `/Users/karim/Project/pokemonProject/reports/r2-scheduler-consolidation-report.md`
- `/Users/karim/Project/pokemonProject/reports/r3-condition-lifecycle-consolidation-report.md`
- `/Users/karim/Project/pokemonProject/reports/battle-roadmap-canonique-v3.1.md`
- `/Users/karim/Project/pokemonProject/reports/combat-ui-ai-audit-and-roadmap.md`

Battle-core :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart`

Runtime / presentation :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/encounter_to_battle_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_transition_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Modeles / donnees :

- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_manifest.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_trainer.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_metadata.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/map_entity_payloads.dart`
- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_encounter.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/project.json`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/maps/golden_field.json`

Tests verite produit :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/project_loader_page_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_launch_save_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

## 6. Validations reellement relancees

Commandes relancees :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

## 7. Resultats reellement obtenus

Resultats observes :

- `packages/map_battle`
  - `dart analyze` : `No issues found!`
  - `dart test` : `All tests passed!`
- `packages/map_runtime`
  - `flutter test ...` : `All tests passed!`
- `examples/playable_runtime_host`
  - `flutter test ...` : `All tests passed!`

Interpretation :

- la baseline actuelle battle/runtime/host est saine ;
- rien dans l'audit precedent n'est invalide par une suite de tests rouge ;
- la roadmap peut donc partir d'une base battleable reelle, pas d'un chantier en feu.

Review separee :

- une review separee a ete tentee aupres de deux reviewers distincts, concentree sur la taille des lots, les derives battle-core et le risque de remettre l'IA dans `battle_session.dart` ;
- aucune reponse exploitable n'est revenue avant timeout ;
- la tentative est donc reelle, mais la synthese finale reste ma responsabilite principale.

## 8. Classification `do_now / do_next / do_soon / defer / not_recommended`

- `Battle Scene UI Pass` : `do_now`
- separation UI combat normale / debug : `do_now`
- backgrounds dynamiques : `do_next`
- seam `BattleBackgroundResolver` : `do_next`
- seam `BattleOpponentPolicy` : `do_soon`
- difficulte `1..10` comme API produit : `do_soon`
- profils internes de difficulte mappes depuis `1..10` : `do_soon`
- scripts de boss / scripts trainer specifiques : `defer`
- IA avec switch intelligent : `defer`
- IA avec replacement intelligent : `defer`
- toute logique IA directement dans `battle_session.dart` : `not_recommended`
- grand framework battle presentation : `not_recommended`
- grand framework IA generique : `not_recommended`
- backgrounds resolus dans `map_battle` : `not_recommended`
- difficulte exposee comme 10 IA completement differentes : `not_recommended`
- traitement des backgrounds via widening de `BattleStartRequest` ou du contrat battle-core : `not_recommended`

## 9. Lecture critique de l'audit existant

L'audit precedent est globalement juste sur trois points :

- il situe bien l'UI combat du cote runtime/presentation ;
- il situe bien les backgrounds dynamiques du cote contexte runtime/map ;
- il situe bien la dette IA du cote d'un futur seam dedie, et non dans `battle_session.dart`.

Ce qu'il fallait renforcer pour obtenir une vraie roadmap d'implementation :

- un ordre de lots plus tranche ;
- une distinction plus explicite entre lot visible produit et lot architecture preparatoire ;
- une position plus nette sur le moment exact ou introduire les backgrounds par rapport au seam IA ;
- des criteres de termine et des risques de derive lot par lot.

Lecture recommandee retenue :

- l'audit etait bon comme carte du terrain ;
- il etait encore trop large pour servir directement de prompt d'implementation ;
- cette roadmap resserre l'ordre de travail en privilegient le gain visible le plus tot possible sans rouvrir un tunnel battle-core.

## 10. Roadmap unique recommandee

Roadmap recommandee :

1. `Lot 1 — Battle Scene UI Pass`
2. `Lot 2 — Contextual Backgrounds`
3. `Lot 3 — BattleOpponentPolicy Seam`
4. `Lot 4 — Difficulty Routing 1..10 -> Internal Profiles`
5. `Lot 5 — Trainer/Boss Scripts and Richer AI Behaviors` plus tard

Pourquoi cet ordre :

- `Lot 1` donne tout de suite le plus gros gain visible sans toucher au battle-core ;
- `Lot 2` est ensuite le lot le plus petit et le plus naturel a brancher sur cette nouvelle scene ;
- `Lot 3` est le plus petit lot architecture propre qui prepare l'IA sans la coder dans `battle_session.dart` ;
- `Lot 4` ne doit pas preceder `Lot 3`, sinon la difficulte se retrouve sans seam sain ;
- `Lot 5` depend des lots precedents et serait premature maintenant.

Alternative rejetee :

- `UI -> seam IA -> difficulte -> backgrounds`

Pourquoi elle est moins bonne ici :

- elle retarde un gain visuel facile alors que le repo a deja les donnees runtime pour un fond contextuel minimal ;
- elle replonge plus vite dans un lot architecture moins visible ;
- elle est defensable pour une equipe qui optimise uniquement la preparation systeme, mais moins bonne pour le plus court chemin produit visible demande ici.

## 11. Detail lot par lot

### Lot 1 — Battle Scene UI Pass

But exact :

- remplacer l'actuel rendu combat trop "debug panel" par une vraie scene de combat runtime ;
- separer clairement scene, HUD, commandes et panneau debug ;
- garder le battle-core, le handoff et la verite produit intacts.

Pourquoi maintenant :

- c'est le plus petit lot visible qui transforme immediatement la perception produit ;
- il reste presque entierement dans `map_runtime` ;
- il ne depend ni d'un seam IA, ni d'assets finaux, ni d'une nouvelle mecanique.

Pourquoi pas avant / pourquoi pas plus tard :

- pas avant : il n'y avait pas encore assez de stabilite battle/runtime avant les phases precedentes ;
- pas plus tard : continuer a travailler l'IA ou les backgrounds sur un shell visuel encore "proto debug" reduirait la valeur perceptible des lots suivants.

Perimetre inclus :

- nouvelle composition de scene de combat dans la presentation runtime ;
- separation visuelle nette entre :
  - decor / fond
  - sprites ou placeholders de positionnement
  - HUD joueur / ennemi
  - zone texte / commandes
  - panneau debug optionnel et distinct
- adaptation du wiring depuis `PlayableMapGame`.

Perimetre exclu :

- nouveaux assets ;
- battle-core ;
- nouvelles mecaniques ;
- IA ;
- backgrounds dynamiques contextuels ;
- refonte globale de toutes les overlays runtime.

Fichiers probablement concernes :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- probablement 1 a 3 nouveaux fichiers presentation sous `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/`
- tests :
  - `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
  - `/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
  - eventuellement `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

Fichiers a eviter :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/**`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

Dependances :

- aucune dependance technique forte autre que la baseline actuelle saine.

Validations a relancer :

- `packages/map_runtime`: `flutter analyze --no-pub` cible presentation si utile
- `packages/map_runtime`: `flutter test` sur `battle_overlay_component_test.dart`, `wild_battle_end_to_end_flow_test.dart`, `phase_a_golden_battle_slice_smoke_test.dart`
- `examples/playable_runtime_host`: `flutter test` sur le lot host demande

Criteres de termine :

- le combat n'apparait plus comme un panneau technique central unique ;
- les HUD joueur / ennemi sont distincts et lisibles ;
- la zone commandes est distincte de la timeline ;
- le debug existe encore mais n'est plus l'UI normale ;
- les tests runtime/host utiles restent verts.

Risques de derive :

- refaire toute l'UI runtime au lieu du seul combat ;
- melanger scene, logique metier et debug dans un seul nouveau composant ;
- sur-concevoir un framework de presentation au lieu d'assembler une scene concrete.

Nature du lot :

- plutot produit visible

### Lot 2 — Contextual Backgrounds

But exact :

- faire varier le fond de combat en fonction du contexte runtime reel ;
- introduire un seam simple de resolution de fond ;
- rester dans une logique d'enrichissement presentation, pas de mecanique battle.

Pourquoi maintenant :

- une fois la scene de combat posee, le fond devient un point d'injection clair ;
- le repo a deja des donnees suffisantes pour un premier resolver honnete ;
- c'est encore un lot visible, petit, et runtime-only.

Pourquoi pas avant / pourquoi pas plus tard :

- pas avant : sur l'overlay actuelle, ce lot finirait en rustine cosmétique sans vraie scene a habiller ;
- pas plus tard : le seam est le plus simple a poser juste apres le shell de scene, avant que d'autres variations visuelles arrivent.

Perimetre inclus :

- introduction d'un `BattleBackgroundResolver` minimal ;
- resolution a partir de `BattleStartRequest + RuntimeMapBundle + MapMetadata + trainer/encounter metadata` ;
- fallback clair et deterministic ;
- support initial volontairement borne :
  - wild vs trainer
  - indoor vs outdoor
  - quelques tags ou map types existants si le repo les expose deja proprement.

Perimetre exclu :

- systeme d'assets final complet ;
- biome universel si le repo ne l'expose pas proprement ;
- meteo, heure, saisons, tags arbitraires sans source canonique forte ;
- tout passage par `map_battle`.

Fichiers probablement concernes :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart` seulement si necessite stricte, sinon a eviter
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_map_bundle.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/load_runtime_map_bundle.dart` uniquement si besoin de contexte deja present mais non transporte
- nouveau resolver probable sous `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/` ou `/src/presentation/flame/` selon responsabilite retenue
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- tests runtime/host associes

Fichiers a eviter :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/**`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

Dependances :

- `Lot 1` recommande pour avoir une scene propre a habiller.

Validations a relancer :

- `packages/map_runtime`: analyze cible sur le resolver + presentation
- `packages/map_runtime`: tests overlay / wild e2e / golden slice
- `examples/playable_runtime_host`: tests launch / golden slice

Criteres de termine :

- le fond de combat n'est plus hardcode ou indistinct ;
- le choix est determine par un seam explicite et teste ;
- les cas non couverts tombent sur un fallback propre ;
- aucune dependance battle-core n'est introduite.

Risques de derive :

- pousser la resolution dans `map_battle` ;
- gonfler `BattleStartRequest` pour transporter trop de presentation ;
- inferer des backgrounds depuis des details de tileset/layers au lieu d'utiliser la metadata existante.

Nature du lot :

- mixte produit visible / architecture locale

### Lot 3 — BattleOpponentPolicy Seam

But exact :

- sortir la logique de choix ennemi de `battle_session.dart` vers un seam dedie ;
- garder un comportement par defaut equivalent ou quasi equivalent a aujourd'hui ;
- preparer proprement la difficulte sans encore l'implanter.

Pourquoi maintenant :

- c'est le plus petit lot architecture qui prepare l'IA proprement ;
- il vient apres deux lots visibles pour eviter le retour immediate dans un tunnel invisible ;
- il permet ensuite d'ajouter la difficulte sans salir le session core.

Pourquoi pas avant / pourquoi pas plus tard :

- pas avant : ce serait replonger trop tot dans un lot peu visible alors qu'un gros gain produit est a portee cote runtime ;
- pas plus tard : toute difficulte ou script sans ce seam risquerait de retomber dans `battle_session.dart`.

Perimetre inclus :

- contrat minimal `BattleOpponentPolicy` ;
- injection locale ou construction explicite dans le seam battle existant ;
- portage du comportement ennemi actuel dans une policy par defaut ;
- scope initial borne :
  - fight-only
  - deterministic ou quasi deterministic simple
  - pas de switch intelligent
  - pas de replacement intelligent
  - pas de targeting riche.

Perimetre exclu :

- difficulte produit ;
- scripts trainer/boss ;
- switch/replacement intelligence ;
- redesign du scheduler ;
- widening request/targeting.

Fichiers probablement concernes :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- un nouveau fichier probable sous `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/` pour la policy
- eventuellement `/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart`
- tests :
  - `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`
  - eventuellement `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Fichiers a eviter :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/**`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` sauf injection strictement necessaire
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`

Dependances :

- aucune dependance technique dure aux lots 1 et 2, mais dependance de sequencement recommandee pour garder de la traction produit.

Validations a relancer :

- `packages/map_battle`: `dart analyze`, `dart test`
- `packages/map_runtime`: tests golden slice / wild flow si integration visible
- `examples/playable_runtime_host`: tests launch si wiring runtime bouge

Criteres de termine :

- `_chooseEnemyAction()` n'est plus un noyau dur encode dans `battle_session.dart` ;
- le seam policy existe et le comportement par defaut reste honnete ;
- aucun contrat battle plus large n'est ouvert ;
- les tests battle/runtime utiles restent verts.

Risques de derive :

- introduire une mini-architecture d'IA abstraite trop tot ;
- laisser la policy voir la queue, le scheduler ou les requests joueur ;
- commencer a glisser des scripts de boss dans le seam de base.

Nature du lot :

- plutot architecture

### Lot 4 — Difficulty Routing 1..10 -> Internal Profiles

But exact :

- exposer une difficulte lisible `1..10` cote produit ;
- la mapper vers quelques profils internes stables ;
- faire evoluer l'IA progressivement sans creer 10 IA monolithiques.

Pourquoi maintenant :

- ce lot n'a de sens qu'une fois le seam policy en place ;
- il permet de donner une API produit claire sans surcharger l'architecture ;
- il reste plus petit et plus honnete qu'un lot de scripts riche.

Pourquoi pas avant / pourquoi pas plus tard :

- pas avant : sans policy seam, la difficulte retombe dans `battle_session.dart` ou dans du wiring runtime sale ;
- pas trop tard : c'est le premier vrai gain fonctionnel cote IA pour le game design.

Perimetre inclus :

- un champ produit de difficulte `1..10` au bon niveau de donnee ou de request ;
- un mapping interne vers quelques profils :
  - par exemple `basic`, `safer`, `pressure`, `trainer-smart`
- eventuellement quelques tunings simples :
  - priorite KO simple
  - eviter les moves manifestement inutiles
  - poids heuristiques limites.

Perimetre exclu :

- 10 comportements completement differents ;
- scripts trainer/boss ;
- switch intelligent ;
- replacement intelligent ;
- targeting riche ;
- difficultes dependantes d'abilities/items/meteo avancee.

Fichiers probablement concernes :

- modeles runtime ou core de trainer/battle request selon l'endroit le plus honnete pour stocker la difficulte
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `/Users/karim/Project/pokemonProject/packages/map_core/lib/src/models/project_trainer.dart` si la difficulte devient metadata trainer persistante
- seam policy battle cree au lot 3
- tests runtime + battle associes

Fichiers a eviter :

- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart` pour la logique de difficulte elle-meme
- presentation runtime, sauf affichage optionnel de debug ou outillage

Dependances :

- depend de `Lot 3`.

Validations a relancer :

- `packages/map_battle`: `dart analyze`, `dart test`
- `packages/map_runtime`: tests request/setup/e2e utiles
- `examples/playable_runtime_host`: tests demo party / launch / golden slice si metadata trainer touchee

Criteres de termine :

- le produit peut exprimer une difficulte `1..10` ;
- cette echelle est mapee vers peu de profils internes lisibles ;
- la difficulte ne vit pas dans `battle_session.dart` ;
- le comportement reste borne au fight-only scope initial.

Risques de derive :

- vouloir rendre chaque cran `1..10` conceptuellement unique ;
- recoder du boss scripting dans les profils ;
- creer une taxonomie d'IA trop fine trop tot.

Nature du lot :

- mixte architecture / data produit

### Lot 5 — Trainer/Boss Scripts and Richer AI Behaviors

But exact :

- introduire plus tard des comportements specifiques de boss ou de trainers importants ;
- ouvrir, si besoin produit reel, des comportements de switch/replacement plus riches.

Pourquoi maintenant :

- justement, **il ne faut pas le faire maintenant** ;
- ce lot n'est defendable qu'apres validation du seam policy et du routing de difficulte.

Pourquoi pas avant / pourquoi pas plus tard :

- pas avant : trop de risque de transformer le seam policy en fourre-tout ;
- plus tard : oui, seulement quand les besoins produit precis sont identifies.

Perimetre inclus :

- scripts trainer/boss explicites ;
- comportements plus riches dependants de metadata ou de scenarios ;
- eventuellement IA de switch/replacement si le produit le justifie reellement.

Perimetre exclu :

- le faire des maintenant ;
- abilities/items/doubles/targeting riche.

Fichiers probablement concernes :

- seam policy battle
- modeles trainer/data si scripting persistant
- runtime trainer battle request
- tests battle/runtime specifiques

Fichiers a eviter :

- le faire avant que `Lot 3` et `Lot 4` soient stabilises

Dependances :

- depend de `Lot 3` et `Lot 4`

Validations a relancer :

- a definir plus tard selon le perimetre exact

Criteres de termine :

- a definir plus tard ; hors scope now

Risques de derive :

- ouvrir un H3/R4 deguise ;
- recruter de la logique speciale partout au lieu de la concentrer dans la policy.

Nature du lot :

- plutot data/content + architecture comportementale

## 12. Ordre de travail recommande

Reponses nettes :

- faut-il faire l'UI avant les backgrounds ? **oui**
- faut-il faire les backgrounds avant le seam IA ? **oui, dans la trajectoire recommandee**
- faut-il faire le seam IA avant l'echelle de difficulte ? **oui, absolument**
- faut-il faire les scripts de boss tout de suite ? **non**
- faut-il absolument eviter une IA riche au debut ? **oui**
- faut-il eviter le switch intelligent dans un premier temps ? **oui**

Ordre le plus productif techniquement et psychologiquement :

1. `Battle Scene UI Pass`
2. `Contextual Backgrounds`
3. `BattleOpponentPolicy Seam`
4. `Difficulty Routing 1..10 -> Internal Profiles`
5. `Trainer/Boss Scripts and Richer AI Behaviors`

Pourquoi cet ordre est le meilleur compromis :

- il donne d'abord un resultat visible et motivant ;
- il garde les deux premiers lots dans le runtime/la presentation ;
- il remet l'architecture battle au service d'un besoin clair, pas l'inverse ;
- il pose ensuite le seam IA juste avant la difficulte, ce qui evite la derive.

## 13. Dependances entre lots

- `Lot 1` n'a pas de dependance dure autre que la baseline actuelle.
- `Lot 2` depend recommandee de `Lot 1`, car il devient alors un branchement simple sur la scene.
- `Lot 3` est techniquement presque independant, mais sequencement recommande apres `Lot 2` pour maintenir un rythme produit visible.
- `Lot 4` depend strictement de `Lot 3`.
- `Lot 5` depend de `Lot 3` et `Lot 4`, et en pratique d'un besoin design plus precis.

## 14. Ce qu'il ne faut surtout pas faire maintenant

- ne pas relancer une phase battle-core large "pour preparer l'IA"
- ne pas mettre la difficulte dans `battle_session.dart`
- ne pas creer 10 IA differentes
- ne pas ouvrir tout de suite le switch intelligent ou le replacement intelligent
- ne pas faire les scripts de boss avant d'avoir le seam policy
- ne pas pousser les backgrounds dans `map_battle`
- ne pas faire un grand framework de battle presentation
- ne pas faire un grand framework IA
- ne pas elargir `BattleStartRequest` juste pour transporter de la presentation si le contexte runtime existe deja ailleurs

## 15. Critique explicite du prompt lui-meme

Parties utiles :

- la demande d'une roadmap unique plutot qu'un audit bis ;
- l'exigence de lots nommes, sequences et defendables ;
- le rappel que l'UI et les backgrounds n'appartiennent pas a `map_battle` ;
- le rappel ferme que la difficulte ne doit pas revenir dans `battle_session.dart`.

Parties discutables :

- imposer de relire un tres grand nombre de fichiers pour une roadmap read-only peut devenir redundant quand un audit recent et verifie existe deja ; ici c'etait acceptable, mais un peu rigide.

Parties trop rigides :

- interdire tout "routing vers R4" est sain comme garde-fou, mais factuellement une roadmap serieuse doit parfois signaler un risque futur de collision avec `switch/replacement/targeting`; je l'ai donc signale comme risque a differer, pas comme chantier a ouvrir.

Parties volontairement resserrees :

- j'ai resserre la roadmap sur 5 lots, dont 4 immediatement actionnables, au lieu d'ouvrir davantage de sous-lots optionnels ;
- j'ai volontairement refuse de multiplier les variantes de sequencement, meme si une inversion `Lot 2` / `Lot 3` reste defendable en theorie.

Pourquoi :

- le but demande etait une trajectoire nette et exploitable, pas une taxonomie de possibilites.

## 16. Autocritique finale

Points forts du travail :

- la roadmap est plus actionnable que l'audit initial ;
- elle garde les premiers gains du cote visible runtime ;
- elle pose un seam IA propre sans le sur-vendre.

Limites :

- une partie du lot backgrounds dependra de l'etat reel des assets disponibles quand l'implementation commencera ;
- le detail exact du mapping `1..10 -> profils` devra etre confirme avec le game design au moment du lot 4 ;
- la priorisation `backgrounds avant seam IA` reste une recommandation produit forte, pas une necessite technique absolue.

## 17. Etat git final utile

Etat reellement observe apres creation de ce report :

- toujours aucune diff tracked ;
- fichiers untracked :
  - `reports/combat-ui-ai-audit-and-roadmap.md`
  - `reports/combat-ui-ai-implementation-roadmap.md`

## 18. Checklist finale

- ai-je reellement produit une roadmap et pas juste un audit bis ? oui
- ai-je garde le travail strictement read-only ? oui
- ai-je evite toute modification de code ? oui
- ai-je relance les validations utiles ? oui
- ai-je classe clairement les futurs lots ? oui
- ai-je propose UNE trajectoire recommandee et non plusieurs variantes molles ? oui
- ai-je identifie le premier lot concret a lancer ? oui
- ai-je garde l'IA hors de `battle_session.dart` ? oui
- ai-je evite de rouvrir inutilement un tunnel battle-core ? oui
- ai-je utilise des sub-agents ? oui
- ai-je tente une review separee ? oui
- ai-je evite toute ecriture Git interdite ? oui

## 19. Decision finale nette

- premier lot recommande : `Lot 1 — Battle Scene UI Pass`
- deuxieme lot recommande : `Lot 2 — Contextual Backgrounds`
- troisieme lot recommande : `Lot 3 — BattleOpponentPolicy Seam`
- plus court chemin sain global :
  - **faire d'abord une vraie scene de combat runtime**
  - **l'habiller ensuite avec des backgrounds contextuels resolus cote runtime**
  - **puis seulement extraire le seam IA et brancher la difficulte `1..10` sur quelques profils internes**
