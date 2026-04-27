# Lot RED-6 — Runtime Scenario Immediate Input Lock / Dialogue Startup Race Fix

## 1. Resume executif honnete

Le lot RED-6 est implemente dans `packages/map_runtime` uniquement.

Le runtime pose maintenant un verrou de gameplay immediat des qu'une interaction bloquante est acceptee, avant tout chargement async de dialogue. Cela couvre :

- dialogue direct ;
- script accepte avant ouverture d'un dialogue ;
- prevention d'une deuxieme interaction pendant un dialogue en cours de chargement ;
- liberation propre du lock si le chargement echoue.

Le joueur ne peut plus bouger entre l'acceptation d'un dialogue/script et l'apparition de l'overlay dialogue.

Point honnete :

- la commande `flutter analyze --no-pub ...` demandee ne finit pas verte a cause d'infos de lint `prefer_const_*` deja presentes dans la surface analysee ; il n'y a plus d'erreur ni de warning bloquant apres le correctif RED-6 ;
- la review separee a ete tentee, mais l'environnement a refuse l'ouverture d'un reviewer avec `agent thread limit reached (max 6)`.

## 2. Etat git initial exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/player_component_test.dart
?? reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
```

### `git diff --stat`

```text
 .../src/presentation/flame/playable_map_game.dart   |  83 ++++-
 .../test/playable_map_game_input_test.dart          | 396 +++++++++++++++++++-
 .../map_runtime/test/player_component_test.dart     |  21 ++
 3 files changed, 495 insertions(+), 5 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
```

## 3. Classification de la dirtiness initiale

### `preexisting_in_scope`

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/player_component_test.dart`
- `reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md`

### `preexisting_out_of_scope`

- aucun fichier visible dans les pre-gates

### `created_by_this_lot`

- `reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md`

### `modified_by_this_lot`

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`

## 4. Fichiers lus

- `reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/dialogue_overlay_component.dart`
- `packages/map_runtime/lib/src/application/load_dialogue_content.dart`
- `packages/map_runtime/lib/src/application/resolve_dialogue.dart`
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/lib/src/application/script_command_executor.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/script_runtime_state.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/scripted_npc_runtime_interaction_test.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`
- `packages/map_runtime/test/scenario_runtime_executor_test.dart`
- `packages/map_runtime/test/script_runtime_mvp_test.dart`

## 5. Fichiers modifies / crees

### Modifies

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`

### Cree

- `reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md`

## 6. Fichiers volontairement non touches

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- surface BAG / capture battle
- transitions warp / connection hors interaction scenario
- `packages/map_runtime/test/player_component_test.dart` : dirty preexistant RED-5, non modifie dans RED-6

## 7. Comportement obtenu

Le runtime introduit maintenant une phase bloquante explicite :

- `_RuntimeFlowPhase.blockingInteraction`

et un verrou logique associe :

- `_activeBlockingInteractionSerial`
- `_activeBlockingInteractionSourceId`
- `_hasPendingDialogueLoad`

Concretement :

- des qu'un dialogue direct est accepte, le gameplay est verrouille avant `loadDialogueContent(...)` ;
- des qu'un script est accepte, le gameplay est verrouille avant que le script ne suspende sur un dialogue ;
- pendant un dialogue pending, le mouvement, les interactions et les affordances overworld sont bloques ;
- si le dialogue charge correctement, le runtime passe ensuite en phase `dialogue` ;
- si le chargement echoue, le verrou est relache proprement et l'overworld redevient jouable ;
- une deuxieme interaction ne peut pas demarrer tant qu'un dialogue pending n'est pas resolu.

## 8. Moment exact ou le lock est pose

Oui : le lock est maintenant pose avant le Future de chargement dialogue.

### Dialogue direct

Dans `_tryOpenDialogue(...)` :

1. la reference dialogue est resolue ;
2. `_beginBlockingInteraction(...)` est appele immediatement ;
3. les inputs de mouvement sont nettoyes ;
4. `_dialogueSessionLoader(resolved)` est lance ;
5. si succes : `_openDialogue(...)` ouvre l'overlay ;
6. si echec : `_releaseBlockingInteraction(...)` rend l'overworld jouable.

Le verrou n'attend plus `_openDialogue(...)`.

### Script / scenario

Dans `_startScriptExecution(...)` :

1. le script est accepte ;
2. `_beginBlockingInteraction(...)` est appele immediatement ;
3. le script execute ensuite ses commandes ;
4. si le script suspend sur `openDialogue`, le runtime reste verrouille pendant le chargement du dialogue ;
5. apres fermeture du dialogue, le script reprend proprement.

## 9. Navigation et anti-stale

Un serial monotone a ete ajoute pour ignorer proprement les retours async obsoletes :

- `_nextBlockingInteractionSerial`
- `_activeBlockingInteractionSerial`

Regle :

- chaque interaction bloquante acceptee prend un nouveau serial ;
- le callback async dialogue verifie que ce serial est toujours actif ;
- sinon la reponse tardive est ignoree sans rouvrir un vieux dialogue.

Cela couvre les cas de reponse async tardive apres annulation ou transition vers un autre etat.

## 10. Que se passe-t-il si le dialogue echoue ?

Le comportement obtenu est :

1. le joueur est bloque pendant l'attente ;
2. si le loader retourne `null` ou lance une erreur controlee, le verrou est relache ;
3. l'overworld redevient jouable ;
4. un fallback utilisateur est affiche via notification.

Pour un dialogue issu d'un script :

- le runtime relache aussi le lock ;
- le script actif est abandonne proprement au lieu de laisser un demi-etat bloque.

## 11. Que se passe-t-il si une deuxieme interaction arrive pendant le pending ?

Elle est refusee.

Le runtime :

- bloque le mouvement ;
- bloque les nouvelles interactions ;
- n'ouvre pas un second overlay ;
- ne lance pas un second chargement de dialogue.

Les logs RED-6 rendent ce comportement visible :

```text
[scenario_lock] accepted source=<id> phase=dialogueLoading serial=<n>
[scenario_lock] input blocked while pending source=<id>
[dialogue] stale response ignored source=<id> serial=<n>
[scenario_lock] released source=<id> reason=<...> serial=<n>
```

## 12. Correction annexe necessaire

Un bug latent de reprise script a ete corrige dans `script_runtime_controller.dart`.

Avant :

- `resume()` ne passait pas a la commande suivante apres une suspension `openDialogue` ;
- le script pouvait reexecuter la meme commande de dialogue.

Apres :

- `resume()` incremente correctement `currentCommandIndex` ;
- `pendingDialogue` est nettoye ;
- le script reprend sur la commande suivante.

Ce point est verrouille par un test d'integration dedie.

## 13. Preuve qu'aucune regression battle / warp / connection n'a ete ouverte

Le lot ne touche pas :

- `map_battle`
- les fichiers BAG / capture
- la logique collision / movement
- la logique warp / connection elle-meme

Les validations runtime de non-regression sont relancees plus bas et restent vertes.

## 14. Tests ajoutes et ce qu'ils prouvent

### `packages/map_runtime/test/playable_map_game_input_test.dart`

- `direct dialogue locks movement before dialogue content finishes loading`
  - prouve qu'un dialogue direct bloque le joueur avant resolution du Future ;
  - prouve que le joueur ne bouge pas pendant l'attente ;
  - prouve que l'overworld redevient jouable apres fermeture du dialogue.

- `failed pending dialogue unlocks gameplay and shows fallback`
  - prouve qu'un echec de chargement ne laisse pas le jeu bloque ;
  - prouve que le fallback utilisateur est visible ;
  - prouve que le mouvement redevient possible apres echec.

- `script dialogue locks gameplay before dialogue overlay is mounted`
  - prouve qu'un script bloque des son acceptation ;
  - prouve que le joueur ne peut pas bouger pendant le chargement du dialogue de script ;
  - prouve que le dialogue s'ouvre ensuite normalement.

- `pending dialogue prevents a second interaction from starting`
  - prouve qu'un deuxieme `A` pendant le pending ne lance pas une deuxieme interaction ;
  - prouve qu'un seul chargement dialogue est en vol.

- `pending scenario blocks overworld input affordances until resolved`
  - prouve que le runtime pending bloque les affordances overworld au-dela du simple mouvement.

### `packages/map_runtime/test/script_system_integration_test.dart`

- `Script resume continues after an openDialogue suspension`
  - prouve que la reprise script continue apres `openDialogue` au lieu de reexecuter la meme commande ;
  - verrouille le correctif de resume lie au nouveau flow RED-6.

## 15. Validations executees et resultats

### TDD rouge initial

```bash
cd packages/map_runtime
flutter test test/playable_map_game_input_test.dart
```

Resultat :

- rouge initial utilise pour construire le seam de dialogue pending et les getters debug.

### Tests RED-6 cibles

```bash
cd packages/map_runtime
flutter test \
  test/playable_map_game_input_test.dart \
  test/script_system_integration_test.dart
```

Resultat :

- vert

### Suite runtime demandee

```bash
cd packages/map_runtime
flutter test \
  test/playable_map_game_input_test.dart \
  test/scripted_npc_runtime_interaction_test.dart \
  test/script_system_integration_test.dart \
  test/scenario_runtime_executor_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Resultat :

- vert

### Validation gameplay

```bash
cd packages/map_gameplay
dart test
```

Resultat :

- vert

### Validation host

```bash
cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
```

Resultat :

- vert

### Analyze demande

```bash
cd packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/dialogue_overlay_component.dart \
  lib/src/application/load_dialogue_content.dart \
  lib/src/application/resolve_dialogue.dart \
  lib/src/application/script_runtime_controller.dart \
  lib/src/application/script_command_executor.dart \
  lib/src/application/scenario_runtime/scenario_runtime_executor.dart \
  test/playable_map_game_input_test.dart \
  test/scripted_npc_runtime_interaction_test.dart \
  test/script_system_integration_test.dart \
  test/scenario_runtime_executor_test.dart
```

Resultat honnete :

- la commande retourne encore non-zero a cause d'infos de lint `prefer_const_*` deja presentes dans la surface analysee ;
- aucune erreur compile RED-6 n'est restante ;
- aucun warning bloquant n'est restant apres suppression du champ temporaire inutilise.

## 16. Logs synthétiques obtenus

Les nouveaux logs RED-6 exposes par le runtime sont de la forme :

```text
[scenario_lock] accepted source=<id> phase=dialogueLoading serial=<n>
[scenario_lock] input blocked while pending source=<id>
[dialogue] content loaded source=<id> elapsedMs=<n>
[scenario_lock] released source=<id> reason=dialogueClosed serial=<n>
```

Ils repondent explicitement aux questions produit :

1. Le lock est pose avant l'async.
2. Le gameplay est bien bloque pendant le pending.
3. Le lock est relache explicitement sur fermeture ou echec.

## 17. Retour de review separee

Une review separee a ete tentee, ciblee sur :

- verrou pose avant l'async ;
- absence de deadlock si dialogue load echoue ;
- absence de double dialogue ;
- reprise script correcte apres fermeture dialogue ;
- absence de regression battle / warp / connection.

Resultat :

- impossible d'obtenir la review dans cet environnement ;
- tentative bloquee par `agent thread limit reached (max 6)`.

Je documente donc honnetement qu'aucune review separée exploitable n'a pu etre produite sur cette session.

## 18. Limites assumees

- le lot ne cherche pas a accelerer le chargement des dialogues ;
- il verrouille immediatement la logique gameplay, ce qui est l'objectif produit du RED ;
- les notifications simples ne deviennent pas des locks permanents ;
- l'analyse demandee reste rouge uniquement pour une baseline de lints info-level hors objectif fonctionnel RED-6.

## 19. Ce qui est reporte

- eventuel prechargement des dialogues si une optimisation produit est souhaitee plus tard ;
- nettoyage de la baseline `prefer_const_*` si un lot hygiene est ouvert ;
- toute optimisation dialogue plus large, hors invariant de verrou immediat.

## 20. Etat git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/application/script_runtime_controller.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/player_component_test.dart
 M packages/map_runtime/test/script_system_integration_test.dart
?? reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
?? reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md
```

### `git diff --stat`

```text
 .../src/application/script_runtime_controller.dart     |   9 +-
 .../src/presentation/flame/playable_map_game.dart      | 364 ++++++++-
 .../test/playable_map_game_input_test.dart             | 902 ++++++++++++++++++++-
 .../map_runtime/test/player_component_test.dart        |  21 +
 .../test/script_system_integration_test.dart           |  66 +-
 5 files changed, 1302 insertions(+), 60 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md
```

## 21. Decision finale

RED-6 est reussi sur le plan fonctionnel :

- le joueur ne peut plus bouger entre l'acceptation d'un dialogue et son affichage ;
- une deuxieme interaction ne peut plus demarrer pendant ce delai ;
- le script/scenario verrouille le gameplay des son acceptation ;
- un echec de chargement relache proprement le lock ;
- les tests couvrent explicitement le delai async, pas seulement le dialogue deja ouvert ;
- aucun fichier `map_battle` ou `map_editor` n'a ete touche.

Point honnete :

- la commande `flutter analyze --no-pub ...` ciblee reste non-verte uniquement pour des lints info-level deja presents dans la baseline analysee.
