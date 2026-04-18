# R1 — Battleable Slice Hardening Report

## 1. Résumé exécutif honnête

`R1` est **réussi**.

Le travail est resté dans un vrai périmètre de hardening, pas d’extension opportuniste.
Il n’y a eu :

- ni nouvelle famille de mécaniques riches ;
- ni widening requests / targeting ;
- ni refactor structurel type `R2` ;
- ni piste IA / difficulté ;
- ni H3 déguisé.

Ce qui a été réellement durci :

- le faux fallback ennemi vers `BattleActionRun()` a été supprimé ;
- l’absence de Struggle n’a pas été maquillée par un faux support, mais le comportement autour du trou a été rendu plus honnête et mieux verrouillé ;
- le hard-fail runtime `no bridgeable move remaining after filtering` a été conservé, mais rendu plus explicite côté diagnostic produit ;
- la vérité seed/support a été réalignée sur `trick_room`, `stealth_rock` et `spikes` ;
- la doc canonique a été mise à jour pour refléter l’état après `R1` et la prochaine étape officielle.

Ce qui n’a pas été corrigé en `R1` volontairement :

- `Struggle` lui-même ;
- la politique locale de double KO ;
- toute ouverture vers forced switch / self switch / phazing / conditions riches ;
- toute piste IA/difficulté.

Décision nette après `R1` :

- `R1` réussi : oui
- sujets réellement durcis : oui
- prochaine étape officielle : `R2 — Scheduler Consolidation`

## 2. Pré-gates réellement exécutés + résultats

Pré-gates exécutés exactement :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat initial exact observé :

- `git status --short --untracked-files=all` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

Interprétation : le worktree était propre au début du passage `R1`.

## 3. Méthode réellement suivie

Ordre réel de travail :

1. pré-gates read-only
2. relecture ciblée du battle core, du runtime, du seed/bootstrap, et des docs canoniques `R0`
3. relance des validations utiles avant changement
4. classification explicite des sujets `R1`
5. utilisation de sub-agents sur trois angles indépendants
6. implémentation minimale et bornée des corrections retenues
7. relance complète des validations ciblées
8. relecture du diff utile
9. tentative de review séparée finale
10. rédaction du présent rapport

Skills / plugins réellement utilisés :

- `Superpowers:using-superpowers`
- `Superpowers:dispatching-parallel-agents`
- `Superpowers:verification-before-completion`
- plugin `Superpowers` effectivement utilisé
- plugin `Game Studio` explicitement demandé par l’utilisateur, mais non retenu comme surface de travail active car la tâche était un hardening battle/runtime/seed documentaire et non un sujet de frontend browser-game, playtest visuel ou HUD

## 4. Périmètre inclus / exclu

### Inclus

Battle core :

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`
- tests battle pertinents

Runtime :

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- tests runtime ciblés battle

Bootstrap / editor :

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

Docs canoniques R0 :

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r0-truth-alignment-report.md`

Référence Showdown locale :

- `pokemon-showdown-master/sim/battle-queue.ts`
- `pokemon-showdown-master/sim/side.ts`
- `pokemon-showdown-master/sim/field.ts`
- `pokemon-showdown-master/data/moves.ts`
- `pokemon-showdown-master/test/sim/misc/hazards.js`
- fichiers Showdown additionnels consultés ponctuellement : `sim/battle.ts`, `sim/pokemon.ts`, `sim/battle-actions.ts`

### Exclu volontairement

- tout refactor de scheduler au-delà du strict existant
- tout widening de `BattleDecisionRequest` / targeting
- toute nouvelle mécanique riche
- toute implémentation d’IA/difficulté
- toute correction opportuniste hors sujets R1 nommés
- toute réécriture large de docs historiques ou de reports anciens

## 5. Classification initiale des sujets R1

| Sujet | Classification initiale | Décision finale |
|---|---|---|
| Struggle | `defer_not_r1` | non implémenté en `R1` |
| fallback IA ennemi | `fix_now_small` | corrigé maintenant |
| hard-fail `no bridgeable move` | `fix_now_small` | conservé et durci maintenant |
| double KO policy | `document_now_only` | gardé et documenté |
| seed/support truth | `fix_now_small` | réaligné maintenant |
| mise à jour doc canonique R0 | `document_now_only` | mise à jour maintenant |
| verrouillage explicite du cas `noLegalChoice` joueur | `fix_now_small` | verrouillé par test |

Pourquoi cette classification :

- implémenter `Struggle` honnêtement aurait demandé soit un nouveau chemin de forced action, soit un nouveau traitement contractuel du “no move left”, ce qui dérive au moins partiellement vers des seams de phase ultérieure ;
- le fallback ennemi `BattleActionRun()` était un faux comportement immédiatement corrigeable avec un blast radius faible ;
- le fail runtime `no bridgeable move` était déjà honnête, donc `R1` devait l’améliorer sans le transformer en faux support ;
- la politique de double KO n’avait pas de correction petite, honnête et Showdown-like disponible dans ce périmètre ;
- le seed/support truth était déjà dépassé par le repo sur trois points concrets, donc `R1` devait les réaligner.

## 6. Fichiers lus

Fichiers battle lus ou relus directement :

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`

Fichiers runtime lus ou relus directement :

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Fichiers bootstrap / seed lus ou relus directement :

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

Docs canoniques et report R0 relus :

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r0-truth-alignment-report.md`

Tests relus ponctuellement pour appuyer les décisions R1 :

- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_stealth_rock_test.dart`
- `packages/map_battle/test/battle_spikes_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

## 7. Validations réellement relancées

Pré-gates :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Validations relancées avant et/ou après patch :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart \
  lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart \
  lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart \
  test/pokemon_moves_bootstrap_seed_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test \
  test/pokemon_moves_bootstrap_seed_test.dart

cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

## 8. Résultats réellement obtenus

### Pré-gates initiaux

- `git status --short --untracked-files=all` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

### Relances finales vertes

Battle :

- `dart analyze` : `No issues found!`
- `dart test` : `All tests passed!`

Runtime ciblé battle :

- `flutter analyze --no-pub ...` : `No issues found!`
- `flutter test ...` : `All tests passed!`

Editor ciblé bootstrap :

- `flutter analyze --no-pub ...` : `No issues found!`
- `flutter test test/pokemon_moves_bootstrap_seed_test.dart` : `All tests passed!`

Host :

- `flutter test ...` : `All tests passed!`

### Incident intermédiaire réel

La première relance post-patch de `map_battle` a échoué à cause de deux nouveaux tests `BattleSession` où `BattleSetup` n’avait pas encore reçu explicitement `isTrainerBattle` et `trainerId`.

Symptômes observés :

- `dart analyze` : 4 erreurs `missing_required_argument`
- `dart test` : échec de chargement de `test/battle_session_test.dart`

Correction apportée :

- ajout explicite de `isTrainerBattle: false` et `trainerId: null` dans les deux setups concernés
- relance complète `dart analyze` + `dart test`
- résultat final : vert complet

## 9. Décisions retenues / rejetées sujet par sujet

### 9.1. Struggle

Décision finale : **volontairement différé en dehors de R1**.

Ce qui a été retenu :

- ne pas implémenter Struggle en `R1`
- verrouiller explicitement le cas joueur “aucun move utilisable et aucun autre choix légal” via `BattleWaitRequest(noLegalChoice)`
- supprimer le faux fallback ennemi qui masquait le sujet au lieu de le traiter honnêtement

Ce qui a été rejeté :

- un faux Struggle implicite côté runtime
- un faux Struggle implicite côté queue
- une extension de `BattleContinueReason` ou du request model juste pour forcer Struggle

Justification :

- un vrai Struggle minimal aurait demandé une nouvelle sémantique d’action forcée ou de choix forcé ;
- ce n’est pas un simple nettoyage local ;
- le plus petit hardening honnête en `R1` était de rendre le trou explicite et cohérent, pas de le maquiller.

### 9.2. Fallback IA ennemi

Décision finale : **corrigé maintenant**.

Changement retenu :

- suppression du fallback `BattleActionRun()` côté ennemi
- ennemi déjà K.O. -> `BattleActionNone()`
- ennemi vivant sans move configuré -> `StateError` explicite
- ennemi vivant avec moves mais sans PP -> `StateError` explicite mentionnant que Struggle reste hors scope

Justification :

- `BattleActionRun` est une vraie action de fuite joueur ;
- la queue battle ignore déjà `Run`, donc ce fallback était doublement mensonger ;
- le fix est petit, local et ne demande aucun refactor structurel.

### 9.3. Hard-fail runtime “no bridgeable move remaining after filtering”

Décision finale : **conservé, mais durci maintenant**.

Changement retenu :

- le fail reste un `RuntimeBattleSetupException`
- le message utilisateur est rendu plus actionnable
- `debugDetails` reçoit `resolutionHint=assign_at_least_one_bridgeable_move`

Ce qui a été rejeté :

- injecter un move par défaut
- ignorer les known moves explicites
- fallback sur un move hors set
- faux support move pour faire démarrer le combat

Justification :

- la frontière runtime doit rester plus stricte que le moteur ;
- ce point est un vrai blocker produit/runtime, mais un blocker honnête ;
- `R1` doit le rendre plus clair, pas le dissoudre artificiellement.

### 9.4. Double KO policy

Décision finale : **gardée et documentée**.

Ce qui a été retenu :

- ne pas modifier `_determineOutcome()` en `R1`
- documenter explicitement que la politique locale reste petite, déterministe, et non Showdown-parity

Ce qui a été rejeté :

- toute correction demi-honnête vers une pseudo-parité Showdown sans seams suffisants
- toute ouverture de nouvelle sémantique d’outcome (tie, faint-order riche, etc.)

Justification :

- Showdown lui-même est plus subtil ici et s’appuie sur des règles de faint order / winner selection que PokeMap ne porte pas encore proprement ;
- il n’y avait pas de fix R1 petit, clair et défendable.

### 9.5. Seed / support truth

Décision finale : **corrigé maintenant**.

Changements retenus :

- `stealth_rock` déplacé dans le groupe structuré supporté
- `spikes` déplacé dans le groupe structuré supporté
- `trick_room` déplacé dans le groupe structuré supporté
- `trick_room.engineSupportLevel` réaligné à `structuredSupported`
- test seed mis à jour pour refléter cette vérité

Ce qui a été rejeté :

- réécriture cosmétique globale du seed
- promotion d’autres entrées hors scope (`whirlwind`, `electric_terrain`, etc.)

Justification :

- ces trois entrées étaient les seuls décalages franchement trompeurs pointés par `R0` ;
- le reste du seed peut rester inchangé sans nouveau mensonge.

### 9.6. Documentation canonique R0 impactée par R1

Décision finale : **mise à jour ciblée maintenant**.

Changements retenus :

- statut canonique après `R1`
- prochaine étape officielle passée à `R2`
- vérité seed/support mise à jour
- vérité sur le fallback ennemi mise à jour
- vérité sur le fail runtime mise à jour

Ce qui a été rejeté :

- toute réécriture large de docs historiques
- toute retouche de reports anciens non nécessaire à la vérité canonique après `R1`

## 10. Justification des fichiers modifiés

### `packages/map_battle/lib/src/battle_session.dart`

Touché parce que le faux fallback ennemi vivait là. C’était le bon point de correction local, sans créer de nouveau framework.

### `packages/map_battle/test/battle_decision_request_test.dart`

Touché pour verrouiller explicitement le cas `noLegalChoice` côté joueur, et donc rendre la dette Struggle visible sans ambiguïté documentaire seulement.

### `packages/map_battle/test/battle_session_test.dart`

Touché pour verrouiller les deux cas ennemis honteux : aucun move configuré, et moves présents mais 0 PP seulement.

### `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

Touché parce que le sujet `no bridgeable move` vit exactement là. Le changement est strictement diagnostic.

### `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

Touché pour verrouiller le nouveau hint de diagnostic.

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

Touché pour verrouiller la propagation honnête du même diagnostic au seam de mapping runtime.

### `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`

Touché pour réaligner la vérité support sur les trois entrées explicitement ciblées par `R0`.

### `packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart`

Touché pour verrouiller cette vérité support.

### `docs/combat/battle-canonical-state-v3.1.md`

Touché parce que `R1` change officiellement la vérité canonique du dépôt sur plusieurs points.

### `docs/combat/battle-roadmap-canonical-v3.1.md`

Touché parce que le statut officiel de la roadmap passe logiquement après `R1`, et que la prochaine étape officielle n’est plus `R1` mais `R2`.

## 11. Justification des fichiers volontairement non touchés

Fichiers volontairement non touchés malgré leur proximité :

- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- host files
- docs historiques hors impact canonique direct R1

Raison commune :

- les toucher aurait soit été inutile, soit aurait commencé à dériver vers `R2`, `R4`, ou vers une extension produit non demandée.

## 12. Incidents rencontrés

1. premier rerun `map_battle` cassé par deux tests ajoutés avec des arguments `BattleSetup` incomplets ; correction immédiate ; rerun vert.
2. plusieurs commandes Flutter ont affiché `Waiting for another flutter command to release the startup lock...` ; bruit d’outillage non bloquant.
3. la review séparée demandée a été tentée avec `Huygens`, puis `Carson`, mais aucun de ces reviewers n’a rendu de findings dans le temps imparti.
4. exigence “inclure le contenu complet de tous les fichiers touchés” utile pour l’archive, mais très lourde dès qu’un fichier massif comme `battle_session.dart` est modifié ; voir critique explicite du prompt plus bas.

## 13. Retour des sub-agents

### Laplace — battle-core / architecture

Ce qu’il a apporté :

- confirmation que `Struggle` lui-même ne doit pas être rouvert en `R1`
- confirmation que le faux fallback ennemi était le vrai point `fix_now_small`
- recommandation de garder la politique double KO en l’état plutôt que de bricoler un faux fix

Ce que j’ai retenu :

- correction du fallback ennemi
- non-implémentation de Struggle
- statu quo documenté sur double KO

Ce que j’ai rejeté :

- l’idée qu’aucun sujet n’était `required_now` ; en pratique, même si le change set est petit, le fallback ennemi était bien un sujet à traiter maintenant

### Pasteur — runtime / bootstrap truth

Ce qu’il a apporté :

- confirmation que le hard-fail runtime est la bonne frontière d’honnêteté
- confirmation que les vrais décalages seed/support étaient surtout `trick_room`, `stealth_rock`, `spikes`
- prudence forte contre toute tentative de faux support move

Ce que j’ai retenu :

- maintien du fail runtime
- durcissement diagnostic uniquement
- réalignement ciblé seed/support

Ce que j’ai rejeté :

- sa lecture plus conservatrice sur `trick_room` comme simple sujet documentaire ; le code et les tests du repo justifient, selon moi, le passage à `structuredSupported` sur le sous-ensemble réellement ouvert

### Dirac — comparaison Showdown ciblée

Ce qu’il a apporté :

- preuve que Showdown auto-convertit le cas “no legal move” en Struggle
- preuve que la politique double KO de PokeMap reste loin de Showdown
- recommandation d’un petit Struggle fallback comme meilleur rapprochement Showdown immédiat

Ce que j’ai retenu :

- la comparaison Showdown sur ces deux écarts
- le constat que PokeMap reste loin de Showdown sur Struggle et double KO

Ce que j’ai rejeté :

- sa recommandation d’implémenter un Struggle minimal en `R1`

Pourquoi :

- le plus petit Struggle honnête dans ce repo n’était pas vraiment un petit patch local ;
- il fallait soit ouvrir un nouveau chemin forced-action, soit élargir la sémantique request/continue ;
- dans le cadre strict de `R1`, j’ai considéré cela trop proche d’un début de widening contractuel.

## 14. Retour du reviewer séparé

Reviewer demandé initialement : `Huygens`

Reviewer alternatif ouvert ensuite faute de retour : `Carson`

Résultat réel :

- `Huygens` n’a pas retourné de findings dans le temps imparti
- `Carson` n’a pas non plus retourné de findings dans le temps imparti

Conséquence :

- je ne prétends pas avoir un reviewer séparé “vert” ou “sans findings” ;
- la vérité honnête est qu’une review séparée a bien été demandée et tentée deux fois, mais n’a pas produit de retour exploitable pendant la fenêtre de travail.

## 15. Critique explicite du prompt lui-même

### Parties utiles

- la contrainte de partir du code réel et des docs canoniques `R0`
- l’interdiction de dériver vers `R2/R3/R4/H3`
- l’obligation de classifier explicitement les sujets avant d’implémenter
- la demande de contredire le prompt si une meilleure lecture est justifiée

### Parties discutables

- l’idée implicite que `Struggle` pourrait être le “vrai” correctif R1 attendu ; dans ce repo, ce n’était pas forcément le plus petit changement honnête
- la demande de full-file contents dans le report, qui est utile pour l’archive mais très coûteuse dès qu’un gros fichier est touché

### Parties trop rigides

- “je veux une review séparée finale si possible” est saine ; mais si le reviewer ne répond pas, il faut accepter un report honnête de timeout plutôt que de simuler un retour
- demander le contenu complet de tous les fichiers touchés, report inclus, crée une récursion absurde pour le rapport lui-même

### Parties volontairement resserrées

- j’ai resserré l’interprétation de “traiter Struggle” en “prendre une décision honnête et verrouiller les garde-fous”, pas en “implémenter quelque chose à tout prix”
- j’ai resserré l’interprétation de “review séparée” en “tentative réelle, quitte à reporter l’absence de retour”, pas en case cochée artificielle

## 16. Autocritique finale

Ce qui reste discutable dans mon propre jugement :

- on peut défendre une autre lecture raisonnable où un micro-Struggle local aurait encore été admissible en `R1` ;
- le passage de `trick_room` à `structuredSupported` repose sur le sous-ensemble réellement ouvert par le repo, pas sur une parité Showdown large ;
- le maintien du double KO en l’état est une décision de prudence de phase, pas une prétention de justesse Showdown.

Ce que je n’ai pas fait :

- je n’ai pas cherché à “corriger” la politique double KO ;
- je n’ai pas ouvert de seam IA/difficulté ;
- je n’ai pas harmonisé toutes les docs historiques, volontairement.

## 17. État git final utile

État git final après implémentation `R1` et avant tout commit :

```bash
 M docs/combat/battle-canonical-state-v3.1.md
 M docs/combat/battle-roadmap-canonical-v3.1.md
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_decision_request_test.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
 M packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/r1-battleable-slice-hardening-report.md
```

`git diff --stat` final utile :

```bash
 docs/combat/battle-canonical-state-v3.1.md         |  22 +--
 docs/combat/battle-roadmap-canonical-v3.1.md       |  14 +-
 packages/map_battle/lib/src/battle_session.dart    |  42 +++---
 .../test/battle_decision_request_test.dart         |  38 +++++
 packages/map_battle/test/battle_session_test.dart  |  94 ++++++++++++
 .../seeds/pokemon_moves_bootstrap_seed.dart        | 167 ++++++++++-----------
 .../test/pokemon_moves_bootstrap_seed_test.dart    |   9 +-
 .../runtime_battle_combatant_seed_builder.dart     |  12 +-
 ...runtime_battle_combatant_seed_builder_test.dart |   6 +
 .../test/runtime_battle_setup_mapper_test.dart     |   6 +
 10 files changed, 287 insertions(+), 123 deletions(-)
```

## 18. Checklist finale

- ai-je gardé le périmètre dans R1 et pas au-delà ? oui
- ai-je traité les edge-cases sales les plus visibles ? oui
- ai-je évité d’ouvrir une nouvelle famille de mécaniques ? oui
- ai-je gardé le runtime honnête ? oui
- ai-je gardé le bootstrap honnête ? oui
- ai-je mis à jour la doc canonique si nécessaire ? oui
- ai-je évité d’implémenter l’IA/difficulté ? oui
- ai-je réellement relancé les validations utiles ? oui
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? tentative réelle oui, retour exploitable non
- ai-je inclus le contenu complet de tous les fichiers touchés ? oui, sauf récursion absurde du report sur lui-même explicitement signalée
- ai-je évité toute écriture Git interdite ? oui

## 19. Décision finale nette

- `R1` réussi ou non : **oui**
- sujets réellement durcis ou non : **oui**
- prochaine étape officielle après `R1` : **`R2 — Scheduler Consolidation`**

## 20. Contenu complet des fichiers touchés

Note importante : le prompt demandait le contenu complet de tous les fichiers touchés. Je l’inclus ci-dessous pour tous les fichiers modifiés par `R1`. Le présent report n’est pas recopié intégralement dans lui-même pour éviter une récursion artificielle sans valeur.


### docs/combat/battle-canonical-state-v3.1.md

```md
# Battle Canonical State v3.1

Statut: canon battle actuel du dépôt après `R1 — Battleable Slice Hardening`

Date de réalignement: 2026-04-18

## But du document

Ce document est la photographie canonique de l'état battle réel de PokeMap.

Il ne décrit ni une intention, ni une vieille phase, ni une promesse.
Il décrit ce que le dépôt sait réellement faire aujourd'hui, sur la base:

1. du code réel
2. des validations réellement relancées
3. du runtime réellement branché
4. du host et du golden slice réellement versionnés
5. du bootstrap réellement présent
6. de la comparaison locale ciblée avec Pokémon Showdown

Ce document remplace comme source de vérité battle actuelle les anciennes formulations qui racontent encore:

- un handoff runtime -> battle à construire
- une battleabilité encore purement future
- un moteur encore “pré-fondations”

## Résumé exécutif honnête

Le moteur battle PokeMap est déjà réel.

Le dépôt supporte déjà un vrai slice `singles-only` avec:

- une vraie battle loop locale
- un vrai handoff runtime -> battle
- une vraie overlay pilotée par une timeline observable
- de vraies battles wild et trainer
- de vraies réserves côté joueur et côté trainer
- une vraie fuite sauvage
- une vraie capture minimale
- un vrai write-back runtime minimal
- un vrai ordre local priorité / vitesse / Trick Room
- PP / accuracy / crit minimaux réels
- dégâts simples + STAB + effectiveness + immunités
- statuts majeurs `par`, `brn`, `psn`, `tox`
- volatiles bornés `protect`, `recharge`, `chargeThenStrike`
- `rain`, `sandstorm`, `trickRoom`
- switch volontaire
- forced replacement joueur
- auto-switch ennemi
- `Stealth Rock`
- `Spikes`

Le moteur n'est pas proche de Pokémon Showdown au sens structurel large.
L'écart dominant n'est plus l'absence de slice battleable. L'écart dominant est:

- la centralisation dans `packages/map_battle/lib/src/battle_session.dart`
- l'étroitesse des contracts requests / targeting / replacement
- la petitesse du scheduler local existant
- l'asymétrie entre conditions moteur et side conditions/hazards

La vérité produit actuelle est la suivante:

- un **golden slice battleable versionné** existe réellement
- un **host lançable** existe réellement
- un **bootstrap projet frais générique** existe réellement, mais il n'est pas équivalent à un projet battle-ready générique

Décision canonique après R1:

- la prochaine vraie étape officielle est `R2 — Scheduler Consolidation`

## État réel du moteur battle

### Ce qui existe déjà réellement

#### Topologie et état

Le moteur a déjà une vraie topologie singles-bornée:

- `BattleSideId`
- `BattleSlotRef`
- un seul slot actif par side
- réserves réelles des deux côtés

Fichiers pivots:

- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`

#### Requests et décisions

Le moteur expose déjà un vrai request model local via `BattleDecisionRequest`:

- `turnChoice`
- `forcedReplacement`
- `continue`
- `wait`

Ce n'est pas le request model riche de Showdown, mais ce n'est plus un placeholder.

Fichier pivot:

- `packages/map_battle/lib/src/battle_decision.dart`

#### Queue / scheduling local

Le moteur a déjà une vraie queue locale:

- `action`
- `endOfTurn`
- `postTurnChecks`
- `autoSwitch`
- `replacementRequired`

`Run` et `Capture` restent volontairement hors queue.

Ce seam existe déjà. Il ne faut plus le raconter comme “à créer”.

Fichier pivot:

- `packages/map_battle/lib/src/battle_queue.dart`

#### Condition engine local

Le moteur a déjà un vrai `BattleConditionEngine` local.

Il sait déjà piloter:

- `runActionAttempt`
- `runHitInterception`
- `runMoveResolved`
- `runForcedContinueTurn`
- `runEndOfTurn`

Ce seam est réel, consommé, et testé.

Fichier pivot:

- `packages/map_battle/lib/src/battle_condition_engine.dart`

#### Résolution de tour

Le moteur résout déjà réellement:

- ordre priorité / vitesse / Trick Room
- accuracy locale
- consommation de PP
- crit minimal
- dégâts simples
- STAB
- effectiveness
- immunités
- statuts majeurs supportés
- volatiles supportés
- field supporté
- switch / replacement / auto-switch
- hazards supportées

Fichier pivot:

- `packages/map_battle/lib/src/battle_session.dart`

#### Restitution observable

Le moteur a déjà une vraie chronologie de tour exploitable via:

- `BattleTurnResult.timeline`

Fichier pivot:

- `packages/map_battle/lib/src/battle_resolution.dart`

### Ce qui est réellement supporté mais borné

- `singles-only`
- un slot actif par side
- targeting local minimal `self/opponent/field/opponentSide/unspecified`
- scheduler local réel mais borné
- condition engine réel mais borné
- side-level mechanics ouvertes sur deux slices dédiées, pas un framework générique
- write-back runtime réel mais étroit

### Ce qui est fragile

- `Struggle` reste absent et volontairement hors scope R1
- l'ennemi sans action légale échoue désormais explicitement au lieu de produire un faux `Run`
- tie-break vitesse égale déterministe joueur d'abord
- priorité de switch localement hardcodée
- politique de double KO locale, maintenue explicitement en R1
- ordre d'entrée hazards local `Stealth Rock` puis `Spikes`
- compatibilités legacy dans `BattleMove` et `BattleTypeChart`

### Ce qui n'est pas supporté honnêtement aujourd'hui

- doubles
- targeting riche Showdown
- `selfSwitch` générique
- `forceSwitch` / phazing générique
- terrains
- `Toxic Spikes`
- `Sticky Web`
- abilities
- items
- système générique de side conditions
- event engine Showdown-like

## État réel du runtime battle

### Handoff runtime -> battle

Le handoff runtime -> battle est réel.

Le runtime sait aujourd'hui:

- construire une `WildBattleStartRequest`
- construire une `TrainerBattleStartRequest`
- mapper ces requests vers un `BattleSetup` réel
- résoudre une lineup joueur active + réserves
- construire des seeds combatants réels à partir des données runtime/projet

Fichiers pivots:

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

### Bridge moves

Le bridge runtime moves -> battle est réel et volontairement strict.

Il transporte honnêtement le sous-ensemble supporté et refuse explicitement le hors-scope.

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

### Overlay battle

L'overlay est branchée sur la vérité moteur actuelle:

- requests
- timeline
- refresh de session

Fichier pivot:

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

### Write-back

Le write-back runtime est réel, mais étroit.

Ce qu'il sait réellement faire:

- write-back des PV sur la party engagée
- marquage trainer defeated
- capture minimale
- whiteout-lite

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

## État réel du bootstrap / seed

### Ce qui existe réellement

- un seed moves embarqué et versionné
- un bootstrap projet frais générique
- un seed de démo explicite et séparé

Fichiers pivots:

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`

### Vérité bootstrap honnête

Le bootstrap projet frais générique ne doit pas être lu comme “projet battle-ready générique”.

Le dépôt distingue maintenant clairement:

- l'initialisation de structure projet
- le seed de données de démo
- le golden slice battleable versionné

### R1 a réaligné les points de vérité bootstrap les plus trompeurs

- `trick_room` n'est plus sous-déclaré dans le seed par rapport au sous-ensemble réellement consommé
- `stealth_rock` et `spikes` ne vivent plus dans un regroupement historiquement trompeur

## Vérité produit réelle

### Golden slice battleable versionné

Le dépôt versionne une vérité produit battleable réelle:

- slice golden battleable
- save de lancement adjacente
- host Flutter lançable
- smoke tests wild et trainer

Fichiers pivots:

- `examples/playable_runtime_host/README.md`
- `examples/playable_runtime_host/golden_battle_slice/README.md`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

### Bootstrap projet frais générique

Un projet fraîchement initialisé n'est pas, à lui seul, la vérité produit battleable.

Le bootstrap générique:

- structure le projet
- seed le minimum nécessaire
- ne garantit pas une battleabilité générique équivalente au golden slice

### Distinction canonique à retenir

Il faut désormais distinguer explicitement:

- **golden slice battleable versionné**: preuve produit actuelle
- **bootstrap projet frais générique**: fondation projet, pas promesse battle complète

## Matrice de support par famille

| Famille | État réel PokeMap | Niveau de proximité Showdown | Notes canoniques |
|---|---|---|---|
| request model | réel mais joueur-only / slot-0 | faible structurellement, honnête localement | seam vivant, non générique |
| side / slot | réel, singles-borné avec réserves | honnête localement, loin du modèle Showdown large | vraie topologie locale |
| targeting | minimal et étroit | faible | pas de moteur de ciblage riche |
| queue / scheduling | réel mais petit | faible structurellement, honnête localement | ne pas le raconter comme absent |
| statuses | réels pour `par/brn/psn/tox` | faible | slice honnête |
| volatiles | réels pour `protect/recharge/chargeThenStrike` | faible | slice honnête |
| field / pseudoWeather | réel pour `rain/sandstorm/trickRoom` | faible structurellement, honnête localement | slice honnête |
| hazards / side conditions | réelles pour `Stealth Rock` et `Spikes` | faible | pas de framework générique |
| switch / replacement | réels | honnête localement, loin du modèle Showdown large | vrai pipeline local |
| PP / accuracy / crit / damage | réels et bornés | honnête localement, loin de la richesse Showdown | loin de la richesse Showdown |
| runtime bridge | réel et strict | n/a produit | très bon niveau de vérité |
| runtime write-back | réel mais étroit | n/a produit | ne pas sur-vendre |
| bootstrap truth | honnête mais curaté | n/a produit | bien distinguer bootstrap et golden slice |
| host / product truth | réel | n/a produit | golden slice = vérité battleable actuelle |

## Écarts structurels principaux vs Showdown

Écarts structurants dominants:

1. `battle_session.dart` reste trop central
2. le scheduler local existe mais reste trop petit pour des flows plus riches
3. les contracts requests / targeting / replacement restent trop serrés
4. les conditions moteur et les side conditions restent asymétriques
5. le runtime bridge est honnête, mais calibré pour un sous-ensemble strict

Écarts mécaniques dominants:

1. pas d'abilities
2. pas d'items
3. pas de targeting riche
4. pas de `forceSwitch` / `selfSwitch` génériques
5. pas de side conditions larges
6. pas de doubles

## Blockers classés

### Architecture

- centralisation excessive dans `battle_session.dart`

### Scheduling

- queue locale réelle mais pas encore assez expressive pour des flows plus riches

### Contracts

- requests / targeting / replacement trop serrés pour certaines mécaniques Showdown-like

### Runtime

- hard-fail “no bridgeable move left” honnête, plus explicite, et toujours volontairement bloquant

### Bootstrap

- les labels/support claims les plus trompeurs ont été réalignés en R1

### Documentation

- roadmap maître historique
- ancien plan battle engine
- ancien README runtime
- certains reports historiques

## Décision officielle après R0

R0 ne change pas le moteur.
R0 ne rajoute aucune mécanique.
R0 ne prétend pas “refonder” le canon.

R0 produit:

- une source canonique d'état battle réel
- une roadmap canonique battle v3.1 propre
- des notes de supersession ciblées sur les documents trompeurs

### Prochaine vraie étape officielle

La prochaine vraie étape officielle après R0 est:

- `R1 — Battleable Slice Hardening`

Raison:

- le slice battle/runtime/host existe déjà
- la prochaine dette dominante n'est pas un manque de vérité documentaire
- la prochaine dette dominante est le durcissement des fragilités déjà connues, sans élargir encore le moteur

```


### docs/combat/battle-roadmap-canonical-v3.1.md

```md
# Battle Roadmap Canonical v3.1

Statut: roadmap battle canonique du dépôt après `R1 — Battleable Slice Hardening`

## But

Continuer à rapprocher PokeMap de Pokémon Showdown sur le périmètre singles utile,
sans faux supports, sans framework mort, et sans transformer `battle_session.dart`
en point d'absorption universel.

## Baseline canonique

Le dépôt a déjà:

- un vrai slice battle `singles-only`
- un vrai handoff runtime -> battle
- une vraie overlay branchée sur la timeline
- un vrai host battleable
- un vrai golden slice versionné
- un vrai bootstrap générique distinct de cette vérité produit

Cette roadmap ne repart pas de zéro.
Elle part d'un moteur déjà vivant mais encore trop centralisé et trop étroit sur
certains seams.

## Règles normatives

1. le code réel prime sur l'ancien récit documentaire
2. un support n'est déclaré que s'il est honnête bout à bout
3. le runtime doit rester au moins aussi strict que le moteur
4. le bootstrap doit rester honnête, pas flatteur
5. aucune étape ne doit empirer la centralisation dans `battle_session.dart`
6. aucune étape ne doit inventer un framework générique sans besoin immédiat

## Séquencement officiel

### Tronc obligatoire

1. `R0 — Truth Alignment`
2. `R1 — Battleable Slice Hardening`
3. `R2 — Scheduler Consolidation`

### Branche conditionnelle après R2

#### Si la prochaine mécanique visée est switch / replacement / targeting centric

Ordre officiel:

1. `R4 — Request / Targeting / Replacement Contract Widening`
2. `H3 — One Showdown-Leaning Micro-Slice`
3. `R3` plus tard si nécessaire

Cas typiques:

- forced switch / phazing minimal
- self switch minimal
- widening honnête des requests de remplacement

#### Si la prochaine mécanique visée est condition-centric

Ordre officiel:

1. `R3 — Condition Lifecycle Consolidation`
2. `H3 — One Showdown-Leaning Micro-Slice`
3. `R4` plus tard si nécessaire

Cas typiques:

- status/volatile plus riche
- side condition plus riche

## Définition normative des étapes

### R0 — Truth Alignment

Nature:

- documentaire
- canonique
- sans mécanique nouvelle

Sortie attendue:

- source canonique de l'état battle réel
- roadmap battle canonique propre
- recadrage ciblé des artefacts documentaires trompeurs

### R1 — Battleable Slice Hardening

Nature:

- hardening
- vérité produit

But:

- durcir le slice déjà ouvert sans l'élargir

Cible:

- fragilités explicites
- mensonges résiduels
- edge-cases honteux

### R2 — Scheduler Consolidation

Nature:

- consolidation d'un seam existant

But:

- réduire la densité de scheduling dans `battle_session.dart`
- clarifier action choisie, action planifiée, exécution et reprise

### R3 — Condition Lifecycle Consolidation

Nature:

- consolidation d'un seam existant

But:

- rendre le cycle de vie des conditions plus cohérent
- réduire l'asymétrie entre conditions moteur et side conditions déjà ouvertes

### R4 — Request / Targeting / Replacement Contract Widening

Nature:

- widening ciblé de contrats existants

But:

- élargir proprement les seams trop serrés pour certains futurs micro-slices

### H3 — One Showdown-Leaning Micro-Slice

Nature:

- enablement mécanique borné

Règle:

- un seul micro-slice
- pas avant prérequis
- pas de mécanique “cool” sans valeur structurelle

## H3: règle canonique

### H3 large maintenant

- non

### H3 micro-slice maintenant

- non comme prochaine étape officielle

### H3 micro-slice après prérequis

- oui, sous conditions

Pré-requis minimaux:

- `R0` terminé
- `R1` terminé
- `R2` terminé
- branche pertinente terminée (`R3` ou `R4`)

## Piste IA / difficulté

L'IA / difficulté ne fait pas partie du tronc principal de convergence Showdown.

Elle vit sur une piste parallèle:

- après `R1`
- idéalement après `R2`
- via un seam de policy dédié
- sans logique de difficulté codée en dur dans `battle_session.dart`

## Statut officiel après R0

`R0` est rempli par:

- `docs/combat/battle-canonical-state-v3.1.md`
- le présent document
- les notes de supersession/document truth ajoutées pendant R0

## Statut officiel après R1

`R1` est rempli par:

- le durcissement des edge-cases les plus honteux du slice battleable
- le maintien explicite du fail runtime `no bridgeable move` sans faux support
- le réalignement seed/support truth sur `trick_room`, `stealth_rock`, `spikes`

## Prochaine étape officielle

La prochaine étape officielle après R1 est:

- `R2 — Scheduler Consolidation`

```


### packages/map_battle/lib/src/battle_session.dart

```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
import 'battle_spikes.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_queue.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;
const BattleConditionEngine _conditionEngine = BattleConditionEngine();

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
/// [rng] - Le seam RNG minimal utilisé par le hit pipeline.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(
  BattleSetup setup, {
  BattleRng rng = const BattleSeededRng(),
}) {
  final player = _buildBattleCombatantFromData(setup.playerPokemon);
  final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
  final playerReserve = setup.playerReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);
  final enemyReserve = setup.enemyReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    playerSide: BattleSideState.player(
      active: player,
      reserve: playerReserve,
    ),
    enemySide: BattleSideState.enemy(
      active: enemy,
      reserve: enemyReserve,
    ),
    field: setup.fieldState,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
    pendingTurn: null,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

BattleCombatant _buildBattleCombatantFromData(
  BattleCombatantData data,
) {
  // On convertit tout le petit contrat battle d'un même bloc pour garantir
  // qu'aucune dimension déjà jugée honnête n'est reperdue lors du passage
  // setup -> state, y compris maintenant l'identité de lineup BE10.
  return BattleCombatant(
    speciesId: data.speciesId,
    lineupIndex: data.lineupIndex,
    level: data.level,
    currentHp: _clampHp(
      currentHp: data.currentHp,
      maxHp: data.maxHp,
    ),
    maxHp: data.maxHp,
    stats: data.stats,
    typing: data.typing,
    majorStatus: data.majorStatus,
    volatileState: data.volatileState,
    abilityId: data.abilityId,
    moves: data.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            majorStatusEffect: m.majorStatusEffect,
            selfVolatileStatus: m.selfVolatileStatus,
            weatherEffect: m.weatherEffect,
            pseudoWeatherEffect: m.pseudoWeatherEffect,
            setsStealthRock: m.setsStealthRock,
            setsSpikes: m.setsSpikes,
            breaksProtect: m.breaksProtect,
            requiresRecharge: m.requiresRecharge,
            chargeThenStrikeEffect: m.chargeThenStrikeEffect,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(growable: false),
  );
}

BattleSideId _opposingSideId(BattleSideId side) {
  return switch (side) {
    BattleSideId.player => BattleSideId.enemy,
    BattleSideId.enemy => BattleSideId.player,
  };
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [decisionRequest] expose la vraie requête de décision joueur
/// 3. [getAvailableChoices] reste disponible comme adaptateur de compatibilité
/// 4. [applyChoice] applique un choix et retourne une nouvelle session
/// 5. Répéter 2-4 jusqu'à ce que [state.isFinished] soit true
/// 6. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
    required this.pendingTurn,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// RNG minimal du moteur battle.
  ///
  /// BE4 choisit de le garder sur la session plutôt que dans `BattleState` :
  /// - l'état observable du combat reste centré sur les combattants / outcomes ;
  /// - le RNG reste un détail de résolution, pas une donnée UI/runtime ;
  /// - mais il reste explicitement injectable et immutable.
  final BattleRng rng;

  /// Continuation locale d'un tour déjà commencé mais suspendu pour demander
  /// un remplacement joueur en plein scheduling.
  ///
  /// Frontière H1 volontairement étroite :
  /// - ce seam n'ouvre pas un moteur général de tours interrompus ;
  /// - il sert uniquement à ne pas mentir quand un switch-in meurt aussitôt sur
  ///   Piège de Roc alors qu'une action adverse reste déjà en file ;
  /// - dès que le joueur choisit le remplacement, la queue reprend là où elle
  ///   s'était arrêtée.
  final _PendingTurnContinuation? pendingTurn;

  /// Requête de décision joueur explicitement exposée par le moteur.
  ///
  /// Phase C choisit ici le plus petit vrai progrès de fondation :
  /// - le moteur ne publie plus seulement une "liste plate de choix" ;
  /// - il expose désormais le type de demande courante :
  ///   tour libre, remplacement forcé, continuation forcée ou attente ;
  /// - runtime/UI peuvent donc consommer un contrat fort sans deviner le
  ///   sens du tour depuis les choix présents, le KO actif ou les volatiles.
  BattleDecisionRequest get decisionRequest => _buildDecisionRequest();

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// Compatibilité locale Phase C :
  /// - cette méthode reste volontairement publique pour limiter le blast
  ///   radius immédiat ;
  /// - mais elle n'est plus la source principale de vérité ;
  /// - elle dérive désormais directement de [decisionRequest].
  ///
  List<PlayerBattleChoice> getAvailableChoices() {
    return decisionRequest.allowedChoices;
  }

  BattleDecisionRequest _buildDecisionRequest() {
    const playerSideId = BattleSideId.player;
    const playerSlot = BattleSlotRef.active(BattleSideId.player);

    if (state.phase == BattlePhase.finished) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        side: playerSideId,
        slot: playerSlot,
        switchChoices: replacementChoices,
        reason: BattleForcedReplacementReason.activeFainted,
        faintedSpeciesId: state.player.speciesId,
      );
    }

    // Cas explicitement borné mais important :
    // - si l'actif est K.O. sans remplaçant valide et que la session n'est pas
    //   déjà terminée, on refuse d'inventer un faux tour libre ;
    // - le runtime voit alors un état "wait" bruyant au lieu d'un menu trompeur.
    if (state.player.isFainted) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.mustRecharge,
      );
    }

    // On construit maintenant explicitement le vrai tour libre :
    // - moves encore jouables ;
    // - switches volontaires valides ;
    // - issues sauvages éventuellement autorisées.
    final moveChoices = <PlayerBattleChoiceFight>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        moveChoices.add(PlayerBattleChoiceFight(i));
      }
    }
    final switchChoices = _availableVoluntarySwitchChoices();
    final captureChoice = !setup.isTrainerBattle && setup.allowCapture
        ? const PlayerBattleChoiceCapture()
        : null;
    final runChoice =
        !setup.isTrainerBattle ? const PlayerBattleChoiceRun() : null;

    if (moveChoices.isEmpty &&
        switchChoices.isEmpty &&
        captureChoice == null &&
        runChoice == null) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      side: playerSideId,
      slot: playerSlot,
      moveChoices: moveChoices,
      switchChoices: switchChoices,
      captureChoice: captureChoice,
      runChoice: runChoice,
    );
  }

  List<PlayerBattleChoiceSwitch> _availableForcedReplacementChoices() {
    if (!state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<PlayerBattleChoiceSwitch> _availableVoluntarySwitchChoices() {
    if (state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<int> _selectableReserveIndices(List<BattleCombatant> reserve) {
    final indices = <int>[];
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        indices.add(i);
      }
    }
    return List<int>.unmodifiable(indices);
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (combatant.isFainted) {
      return null;
    }

    final volatileState = combatant.volatileState;
    final pendingCharge = volatileState.pendingCharge;
    if (pendingCharge != null) {
      if (pendingCharge.moveIndex < 0 ||
          pendingCharge.moveIndex >= combatant.moves.length) {
        throw StateError(
          'Le combattant $combatantLabel porte un move chargé invalide (index ${pendingCharge.moveIndex}).',
        );
      }

      final chargedMove = combatant.moves[pendingCharge.moveIndex];
      if (chargedMove.id != pendingCharge.moveId ||
          chargedMove.chargeThenStrikeEffect == null) {
        throw StateError(
          'Le combattant $combatantLabel porte un état de charge incohérent pour le move ${pendingCharge.moveId}.',
        );
      }

      return BattleActionFight(
        chargedMove,
        moveIndex: pendingCharge.moveIndex,
      );
    }

    if (volatileState.mustRecharge) {
      return const BattleActionRecharge();
    }

    return null;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Depuis BE4, la résolution d'un move n'est plus "toujours hit" :
  /// - la tentative peut consommer 1 PP puis rater ;
  /// - ce miss n'annule ni l'ordre du tour ni la consommation ;
  /// - seuls les effets réellement supportés sont alors appliqués sur hit.
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    final request = decisionRequest;
    if (request is BattleWaitRequest) {
      throw StateError(
        'Aucune décision joueur n’est attendue actuellement (${request.reason.name}).',
      );
    }
    if (!request.allows(choice)) {
      throw _illegalChoiceStateError(request, choice);
    }
    if (request case BattleForcedReplacementRequest()) {
      if (pendingTurn != null) {
        return _resumePendingTurnWithReplacement(
          choice as PlayerBattleChoiceSwitch,
        );
      }
      return _applyForcedPlayerReplacement(choice as PlayerBattleChoiceSwitch);
    }

    final forcedPlayerAction = switch (request) {
      BattleContinueRequest() => _resolveForcedAction(
          combatantLabel: 'player',
          combatant: state.player,
        ),
      _ => null,
    };
    if (request is BattleContinueRequest && forcedPlayerAction == null) {
      throw StateError(
        'La request ${request.kind.name} ne correspond plus à un vrai tour forcé côté moteur.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (request is! BattleContinueRequest && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        pendingTurn: null,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        pendingTurn: null,
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _resolveForcedAction(
          combatantLabel: 'enemy',
          combatant: state.enemy,
        ) ??
        _chooseEnemyAction();

    // Phase 3: Résoudre le tour.
    //
    // BE3 corrige ici une ancienne approximation mensongère :
    // - on ne résout plus "joueur puis ennemi quoi qu'il arrive" ;
    // - on calcule un ordre minimal honnête une seule fois au début du tour ;
    // - priorité d'abord, puis vitesse effective, puis tie-break déterministe ;
    // - aucun recalcul rétroactif si un move modifie la vitesse pendant ce tour.
    //
    // Frontière volontairement stricte :
    // - pas de queue générique façon Showdown ;
    // - pas de PRNG ;
    // - pas de système générique de switch / hooks / réserves façon Showdown ;
    // - BE10 ajoute seulement le plus petit switch singles nécessaire :
    //   actif + réserve, switch volontaire joueur, remplacement après K.O. ;
    // - BE7 ajoute seulement un résiduel de fin de tour local pour les
    //   statuts majeurs supportés ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce
    //   tour et leur clôture immédiate.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase F déplace ici la source de vérité du séquencement :
    // - `_resolveTurn` ne renvoie plus seulement "les deux actions puis un
    //   append post-traité" ;
    // - il consomme désormais une vraie queue locale incluant fin de tour et
    //   checks post-résolution ;
    // - le résultat qu'il renvoie est donc déjà le tour complet canonique.
    final turnResult = resolvedTurn.turnResult;

    // Phase 5: Vérifier si le combat est fini
    final outcome = resolvedTurn.pendingTurn != null
        ? null
        : _determineOutcome(
            resolvedTurn.playerSide,
            resolvedTurn.enemySide,
            resolvedTurn.field,
          );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: resolvedTurn.playerSide,
      enemySide: resolvedTurn.enemySide,
      field: resolvedTurn.field,
      // On conserve maintenant la trace du dernier tour même s'il termine le
      // combat :
      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
      //   application de statut terminale redeviendraient invisibles ;
      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
      //   passent pas par `_resolveTurn`.
      currentTurn: turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
      pendingTurn: resolvedTurn.pendingTurn,
    );
  }

  BattleSession _applyForcedPlayerReplacement(PlayerBattleChoiceSwitch choice) {
    // Review Phase F:
    // - le remplacement joueur inter-tour était encore sur un chemin manuel ;
    // - cela laissait une portion déjà supportée du flow hors scheduler
    //   canonique ;
    // - on le fait donc aussi passer par la queue, mais sans lui inventer
    //   une fausse fin de tour ni des checks post-résolution.
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction:
          BattleActionSwitch(reserveIndex: choice.reserveIndex),
      originalEnemyAction: const BattleActionNone(),
    );
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
    }

    final followUpReplacementIndex =
        _firstUsableReserveIndex(turn.playerSide.reserve);
    if (turn.playerSide.active.isFainted && followUpReplacementIndex != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        side: BattleSideId.player,
        fromSpeciesId: turn.playerSide.active.speciesId,
      );
      turn.switchEvents.add(replacementRequiredEvent);
      turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    final outcome = _determineOutcome(
      turn.playerSide,
      turn.enemySide,
      turn.field,
    );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          stealthRockEvents:
              List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
          spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
          switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
          timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
        ),
        outcome: outcome,
      ),
      setup: setup,
      rng: turn.rng,
      pendingTurn: null,
    );
  }

  BattleSession _resumePendingTurnWithReplacement(
      PlayerBattleChoiceSwitch choice) {
    final pending = pendingTurn;
    if (pending == null) {
      throw StateError(
        'Aucune continuation de tour n’est disponible pour reprendre un remplacement joueur.',
      );
    }

    final turn = _QueuedTurnContext.resume(pending);
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
        ...pending.remainingSteps,
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
      if (turn.pendingTurn != null) {
        break;
      }
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    final outcome = turn.pendingTurn != null
        ? null
        : _determineOutcome(
            turn.playerSide,
            turn.enemySide,
            turn.field,
          );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: _buildTurnResultFromContext(
          turn: turn,
          playerAction: pending.playerAction,
          enemyAction: pending.enemyAction,
        ),
        outcome: outcome,
      ),
      setup: setup,
      rng: turn.rng,
      pendingTurn: turn.pendingTurn,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required BattleSideState side,
    required int reserveIndex,
    required bool wasForced,
  }) {
    final reserve = side.reserve;
    if (reserveIndex < 0 || reserveIndex >= reserve.length) {
      throw RangeError.index(reserveIndex, reserve, 'reserveIndex');
    }

    final incoming = reserve[reserveIndex];
    if (incoming.isFainted) {
      throw StateError(
        'Le switch demandé vise un Pokémon de réserve déjà K.O.',
      );
    }

    // BE10 choisit de conserver une réserve de taille stable :
    // - le membre entrant quitte la réserve ;
    // - l'actif sortant y retourne au même emplacement après reset ;
    // - chaque participant battle reste donc présent exactement une fois,
    //   ce qui simplifie le write-back runtime final.
    final updatedReserve = List<BattleCombatant>.of(reserve);
    updatedReserve[reserveIndex] = side.active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      side: side.withActiveAndReserve(
        active: incoming,
        reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      ),
      event: BattleSwitchEvent.switched(
        side: side.id,
        fromSpeciesId: side.active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        return i;
      }
    }
    return null;
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        final move = state.player.moves[choice.moveIndex];
        if (!move.hasUsablePp) {
          throw StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
        return BattleActionFight(
          move,
          moveIndex: choice.moveIndex,
        );
      }
      throw StateError(
        'Le choix Fight(${choice.moveIndex}) vise un slot move invalide.',
      );
    } else if (choice is PlayerBattleChoiceSwitch) {
      if (choice.reserveIndex < 0 ||
          choice.reserveIndex >= state.playerReserve.length) {
        throw StateError(
          'Le switch demandé vise un index de réserve invalide (${choice.reserveIndex}).',
        );
      }
      if (state.playerReserve[choice.reserveIndex].isFainted) {
        throw StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
      return BattleActionSwitch(
        reserveIndex: choice.reserveIndex,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
    }
    throw StateError(
      'Type de choix joueur non supporté par _choiceToAction: ${choice.runtimeType}.',
    );
  }

  String _describePlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) => 'Fight($moveIndex)',
      PlayerBattleChoiceSwitch(:final reserveIndex) => 'Switch($reserveIndex)',
      PlayerBattleChoiceRun() => 'Run()',
      PlayerBattleChoiceCapture() => 'Capture()',
      PlayerBattleChoiceContinue() => 'Continue()',
    };
  }

  StateError _illegalChoiceStateError(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    // On garde ici quelques diagnostics métier précis pour ne pas perdre en
    // lisibilité par rapport à l'ancien monde "liste plate" :
    // - un move à 0 PP doit rester identifiable comme tel ;
    // - un switch invalide ou vers une réserve K.O. mérite aussi un message
    //   ciblé ;
    // - tout le reste peut retomber sur le message générique request/kind.
    if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
      if (moveIndex >= 0 && moveIndex < state.player.moves.length) {
        final move = state.player.moves[moveIndex];
        if (!move.hasUsablePp) {
          return StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
      }
    }

    if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
      if (reserveIndex < 0 || reserveIndex >= state.playerReserve.length) {
        return StateError(
          'Le switch demandé vise un index de réserve invalide ($reserveIndex).',
        );
      }
      if (state.playerReserve[reserveIndex].isFainted) {
        return StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
    }

    return StateError(
      'Le choix ${_describePlayerChoice(choice)} est illégal pour la request courante ${request.kind.name}.',
    );
  }

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // R1 refuse toujours de rouvrir Struggle, mais supprime le vieux faux
    // fallback "Run" côté ennemi :
    // - `BattleActionRun` est une vraie fuite joueur, pas un "tour vide" ;
    // - la queue ignore déjà `Run`, donc le garder ici maquillait juste un état
    //   moteur malformé sans le traiter honnêtement ;
    // - un ennemi déjà K.O. ne doit simplement plus agir ;
    // - un ennemi vivant sans move configuré ou sans PP reste une dette visible
    //   et doit échouer explicitement.
    if (state.enemy.isFainted) {
      return const BattleActionNone();
    }
    if (state.enemy.moves.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a aucun move configuré et ne peut pas agir honnêtement.',
      );
    }
    for (var i = 0; i < state.enemy.moves.length; i++) {
      if (state.enemy.moves[i].hasUsablePp) {
        return BattleActionFight(
          state.enemy.moves[i],
          moveIndex: i,
        );
      }
    }
    throw StateError(
      'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
    );
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne l'état résolu du tour :
  /// - les exécutions à afficher ;
  /// - l'état joueur après dégâts / boosts ;
  /// - l'état ennemi après dégâts / boosts.
  ///
  /// Phase F remplace ici l'ancien pipeline figé par une vraie queue locale :
  /// - l'ordre initial reste calculé honnêtement une seule fois au début ;
  /// - mais les étapes du tour passent ensuite par une file consommée ;
  /// - la fin de tour et les checks post-résolution sont insérés explicitement ;
  /// - les remplacements déjà supportés ne sont plus appendés "à côté" du tour.
  _ResolvedBattleTurn _resolveTurn(
    BattleAction playerAction,
    BattleAction enemyAction,
  ) {
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction: playerAction,
      originalEnemyAction: enemyAction,
    );
    final queue = BattleTurnQueue(
      _buildInitialTurnQueue(
        playerAction: playerAction,
        enemyAction: enemyAction,
        player: turn.playerSide.active,
        enemy: turn.enemySide.active,
        field: turn.field,
      ),
    );

    while (!queue.isEmpty) {
      final step = queue.takeNext();
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: step,
      );
      if (turn.pendingTurn != null) {
        break;
      }
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    return _ResolvedBattleTurn(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      turnResult: _buildTurnResultFromContext(
        turn: turn,
        playerAction: playerAction,
        enemyAction: enemyAction,
      ),
      pendingTurn: turn.pendingTurn,
    );
  }

  BattleTurnResult _buildTurnResultFromContext({
    required _QueuedTurnContext turn,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return BattleTurnResult(
      playerAction: playerAction,
      enemyAction: enemyAction,
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  Iterable<BattleQueueStep> _buildInitialTurnQueue({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) sync* {
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
    );

    for (final orderedAction in orderedActions) {
      if (!isBattleQueueManagedAction(orderedAction.action)) {
        continue;
      }

      yield BattleQueueActionStep(
        side: orderedAction.side,
        slot: BattleSlotRef.active(orderedAction.side),
        action: orderedAction.action,
        wasForced: false,
      );
    }
  }

  void _appendTurnTailWhenActionPhaseDrains({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    if (turn.turnTailScheduled || !queue.isEmpty) {
      return;
    }

    // La queue n'insère la fin de tour qu'une seule fois, exactement quand les
    // actions ordonnées du tour ont été consommées. C'est ce point d'insertion
    // explicite qui remplace l'ancien "et maintenant on fait la fin de tour"
    // codé en dur en bas de `_resolveTurn`.
    queue.pushBack(const BattleQueueEndOfTurnStep());
    queue.pushBack(const BattleQueuePostTurnChecksStep());
    turn.turnTailScheduled = true;
  }

  void _executeQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueStep step,
  }) {
    switch (step) {
      case BattleQueueActionStep():
        _executeActionQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueEndOfTurnStep():
        _executeEndOfTurnQueueStep(turn);
      case BattleQueuePostTurnChecksStep():
        _executePostTurnChecksQueueStep(
          queue: queue,
          turn: turn,
        );
      case BattleQueueAutoSwitchStep():
        _executeAutoSwitchQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueReplacementRequiredStep():
        _executeReplacementRequiredQueueStep(turn: turn, step: step);
    }
  }

  void _executeActionQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueActionStep step,
  }) {
    final actingSide = turn.side(step.side);
    final opposingSide = turn.side(_opposingSideId(step.side));

    if (step.action case BattleActionFight(:final move, :final moveIndex)) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _resolveMoveExecution(
        attackerSlot: actingSide.activeSlotRef,
        move: move,
        moveIndex: moveIndex,
        attacker: actingSide.active,
        defender: opposingSide.active,
        field: turn.field,
        targetSlot: opposingSide.activeSlotRef,
        rng: turn.rng,
      );
      turn.updateActive(step.side, resolution.attacker);
      turn.updateActive(_opposingSideId(step.side), resolution.defender);
      turn.field = resolution.field;
      turn.rng = resolution.rng;
      if (resolution.execution != null) {
        turn.executions.add(resolution.execution!);
      }
      turn.statusEvents.addAll(resolution.statusEvents);
      turn.volatileEvents.addAll(resolution.volatileEvents);
      turn.fieldEvents.addAll(resolution.fieldEvents);
      turn.timeline.addAll(resolution.timeline);
      final stealthRockResolution = _resolveStealthRockMoveEffect(
        move: move,
        didResolveHit: resolution.execution?.didHit == true,
        targetSide: turn.side(_opposingSideId(step.side)),
      );
      if (stealthRockResolution != null) {
        turn.updateSide(
          _opposingSideId(step.side),
          stealthRockResolution.side,
        );
        turn.stealthRockEvents.addAll(stealthRockResolution.events);
        turn.timeline
            .addAll(_turnEventsFromStealthRock(stealthRockResolution.events));
      }
      final spikesResolution = _resolveSpikesMoveEffect(
        move: move,
        didResolveHit: resolution.execution?.didHit == true,
        targetSide: turn.side(_opposingSideId(step.side)),
      );
      if (spikesResolution != null) {
        turn.updateSide(
          _opposingSideId(step.side),
          spikesResolution.side,
        );
        turn.spikesEvents.addAll(spikesResolution.events);
        turn.timeline.addAll(_turnEventsFromSpikes(spikesResolution.events));
      }
      return;
    }

    if (step.action case BattleActionSwitch(:final reserveIndex)) {
      final resolution = _resolveSwitchAction(
        side: actingSide,
        reserveIndex: reserveIndex,
        wasForced: step.wasForced,
      );
      turn.updateSide(step.side, resolution.side);
      turn.switchEvents.add(resolution.event);
      turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
      final entryHazards = _resolveEntryHazards(
        side: turn.side(step.side),
      );
      turn.updateSide(step.side, entryHazards.side);
      turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
      turn.timeline
          .addAll(_turnEventsFromStealthRock(entryHazards.stealthRockEvents));
      turn.spikesEvents.addAll(entryHazards.spikesEvents);
      turn.timeline.addAll(_turnEventsFromSpikes(entryHazards.spikesEvents));

      final sideAfterEntry = turn.side(step.side);
      if (sideAfterEntry.active.isFainted &&
          step.side == BattleSideId.player &&
          _firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
          !queue.isEmpty) {
        _suspendTurnForImmediatePlayerReplacement(
          queue: queue,
          turn: turn,
        );
      }
      return;
    }

    if (step.action is BattleActionRecharge) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _conditionEngine.runForcedContinueTurn(
        combatantSlot: actingSide.activeSlotRef,
        combatant: actingSide.active,
      );
      turn.updateActive(step.side, resolution.combatant);
      turn.volatileEvents.addAll(resolution.volatileEvents);
      turn.timeline.addAll(_turnEventsFromVolatile(resolution.volatileEvents));
    }
  }

  void _executeEndOfTurnQueueStep(_QueuedTurnContext turn) {
    final residualResolution = _conditionEngine.runEndOfTurn(
      player: turn.playerSide.active,
      enemy: turn.enemySide.active,
      field: turn.field,
    );
    turn.updateActive(BattleSideId.player, residualResolution.player);
    turn.updateActive(BattleSideId.enemy, residualResolution.enemy);
    turn.field = residualResolution.field;
    turn.statusEvents.addAll(residualResolution.statusEvents);
    turn.fieldEvents.addAll(residualResolution.fieldEvents);
    turn.timeline
        .addAll(_turnEventsFromStatus(residualResolution.statusEvents));
    turn.timeline.addAll(_turnEventsFromField(residualResolution.fieldEvents));
  }

  void _executePostTurnChecksQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    final enemyReplacementIndex =
        _firstUsableReserveIndex(turn.enemySide.reserve);
    if (turn.enemySide.active.isFainted && enemyReplacementIndex != null) {
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reserveIndex: enemyReplacementIndex,
        ),
      );
    }

    if (turn.playerSide.active.isFainted &&
        !turn.enemySide.active.isFainted &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      // Tant qu'une chaîne d'auto-switch ennemi reste possible, on refuse
      // d'annoncer le remplacement joueur trop tôt :
      // - sinon la timeline raconterait "le joueur doit remplacer" avant que
      //   l'ennemi ait fini d'entrer réellement ;
      // - en H1 Stealth Rock, un premier remplaçant ennemi peut même mourir
      //   en entrant, ce qui doit rester visible avant la request joueur.
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: turn.playerSide.active.speciesId,
        ),
      );
    }
  }

  void _executeAutoSwitchQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueAutoSwitchStep step,
  }) {
    final resolution = _resolveSwitchAction(
      side: turn.side(step.side),
      reserveIndex: step.reserveIndex,
      wasForced: true,
    );
    turn.updateSide(step.side, resolution.side);
    turn.switchEvents.add(resolution.event);
    turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
    final entryHazards = _resolveEntryHazards(
      side: turn.side(step.side),
    );
    turn.updateSide(step.side, entryHazards.side);
    turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
    turn.timeline
        .addAll(_turnEventsFromStealthRock(entryHazards.stealthRockEvents));
    turn.spikesEvents.addAll(entryHazards.spikesEvents);
    turn.timeline.addAll(_turnEventsFromSpikes(entryHazards.spikesEvents));

    if (turn.side(step.side).active.isFainted) {
      final nextReserveIndex =
          _firstUsableReserveIndex(turn.side(step.side).reserve);
      if (nextReserveIndex != null) {
        queue.pushBack(
          BattleQueueAutoSwitchStep(
            side: step.side,
            slot: step.slot,
            reserveIndex: nextReserveIndex,
          ),
        );
        return;
      }
    }

    if (step.side == BattleSideId.enemy &&
        turn.playerSide.active.isFainted &&
        !turn.enemySide.active.isFainted &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: turn.playerSide.active.speciesId,
        ),
      );
    }
  }

  void _executeReplacementRequiredQueueStep({
    required _QueuedTurnContext turn,
    required BattleQueueReplacementRequiredStep step,
  }) {
    final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
      side: step.side,
      fromSpeciesId: step.faintedSpeciesId,
    );
    turn.switchEvents.add(replacementRequiredEvent);
    turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
  }

  void _suspendTurnForImmediatePlayerReplacement({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    // H1/H2 ouvrent ici le plus petit vrai seam d'interruption :
    // - uniquement pour un remplacement joueur devenu obligatoire en plein tour
    //   parce qu'un switch-in vient de mourir sur un hazard d'entrée déjà
    //   réellement supporté ;
    // - on ne transforme pas cela en scheduler général ni en bus d'interruption ;
    // - on capture juste assez d'état pour reprendre honnêtement les étapes déjà
    //   en file après le futur choix de remplacement.
    final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
      side: BattleSideId.player,
      fromSpeciesId: turn.playerSide.active.speciesId,
    );
    turn.switchEvents.add(replacementRequiredEvent);
    turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    turn.pendingTurn = _PendingTurnContinuation.capture(
      turn: turn,
      remainingSteps: queue.drainRemainingSteps(),
      playerAction: turn.originalPlayerAction ?? const BattleActionNone(),
      enemyAction: turn.originalEnemyAction ?? const BattleActionNone(),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (!isBattleQueueManagedAction(playerAction) ||
        !isBattleQueueManagedAction(enemyAction)) {
      return <_OrderedBattleAction>[
        _OrderedBattleAction(
          side: BattleSideId.player,
          action: playerAction,
        ),
        _OrderedBattleAction(
          side: BattleSideId.enemy,
          action: enemyAction,
        ),
      ];
    }

    final playerPriority = _priorityForResolvedAction(playerAction);
    final enemyPriority = _priorityForResolvedAction(enemyAction);
    if (playerPriority != enemyPriority) {
      return playerPriority > enemyPriority
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
            ];
    }

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
    final trickRoomActive = _conditionEngine.doesFieldInvertSpeedOrder(field);
    if (playerSpeed != enemySpeed) {
      final playerActsFirst =
          trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
      return playerActsFirst
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                side: BattleSideId.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                side: BattleSideId.player,
                action: playerAction,
              ),
            ];
    }

    // Tie-break volontairement déterministe et documenté :
    // - pas de PRNG pour résoudre les égalités d'ordre ;
    // - BE4 introduit bien un seam RNG pour le hit pipeline, mais pas pour ce
    //   tie-break ;
    // - pas de Fischer-Yates façon Showdown ;
    // - Trick Room n'inverse pas ce tie-break : seul l'ordre de vitesse est
    //   renversé ;
    // - on choisit "joueur avant ennemi" parce que c'est stable, testable,
    //   et cohérent avec l'historique du moteur jusqu'ici.
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        side: BattleSideId.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        side: BattleSideId.enemy,
        action: enemyAction,
      ),
    ];
  }

  int _priorityForResolvedAction(BattleAction action) {
    return switch (action) {
      // Politique BE10 explicitement simplifiée :
      // - un switch volontaire singles résout avant un `Fight` standard ;
      // - on n'ouvre pas pour autant une vraie taxonomie Showdown de priorités
      //   de switch, selfSwitch, forceSwitch, etc. ;
      // - cette constante locale suffit au sous-ensemble honnête du lot.
      BattleActionSwitch() => 6,
      BattleActionFight(:final move) => move.priority,
      BattleActionRecharge() => 0,
      _ => 0,
    };
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit ;
  /// - BE7 ajoute ensuite un petit sous-ensemble `applyStatus` et un blocage
  ///   d'action par paralysie, sans ouvrir un système de statuts complet.
  ///
  /// Cette application immédiate reste importante :
  /// - un `growl` du joueur peut déjà réduire une contre-attaque physique
  ///   ennemie plus tard dans le même tour s'il touche ;
  /// - mais un changement de `speed` ne réordonne jamais rétroactivement un
  ///   tour déjà ordonné au début de `_resolveTurn`.
  _ResolvedMoveExecution _resolveMoveExecution({
    required BattleSlotRef attackerSlot,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleSlotRef targetSlot,
    required BattleRng rng,
  }) {
    final actionAttempt = _conditionEngine.runActionAttempt(
      attackerSlot: attackerSlot,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
      rng: rng,
    );

    if (actionAttempt.outcome == BattleActionAttemptOutcome.preventedAction) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: actionAttempt.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromStatus(actionAttempt.statusEvents),
      );
    }

    if (actionAttempt.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: actionAttempt.volatileEvents,
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromVolatile(actionAttempt.volatileEvents),
      );
    }

    final preHitVolatileEvents =
        List<BattleVolatileEvent>.of(actionAttempt.volatileEvents);
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionAttempt.rng,
    );

    if (!hitCheck.didHit) {
      final missExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: actionAttempt.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: false,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: missExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: missExecution,
        ),
      );
    }

    final hitInterception = _conditionEngine.runHitInterception(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: actionAttempt.attacker,
      defender: defender,
    );
    preHitVolatileEvents.addAll(hitInterception.volatileEvents);

    if (hitInterception.blockedByProtect) {
      final blockedExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: hitInterception.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: true,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: hitInterception.attacker,
        defender: hitInterception.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: blockedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: blockedExecution,
        ),
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: hitInterception.attacker,
      defender: hitInterception.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    final updatedAttacker = damageResult.wasImmune
        ? hitInterception.attacker
        : hitInterception.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? hitInterception.defender
        : hitInterception.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final postMoveConditions = _conditionEngine.runMoveResolved(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: updatedAttacker,
      defender: defenderAfterHit,
      field: field,
      wasImmune: damageResult.wasImmune,
      rng: damageResult.nextRng,
    );
    final preExecutionVolatileEvents =
        List<BattleVolatileEvent>.unmodifiable(preHitVolatileEvents);
    final allVolatileEvents = <BattleVolatileEvent>[
      ...preHitVolatileEvents,
      ...postMoveConditions.volatileEvents,
    ];

    final resolvedExecution = BattleMoveExecution(
      attackerSlot: attackerSlot,
      move: postMoveConditions.attacker.moves[moveIndex],
      targetKind: _resolveExecutionTargetKind(move),
      targetSlot: _resolveExecutionTargetSlot(
        move: move,
        attackerSlot: attackerSlot,
        opponentSlot: targetSlot,
      ),
      targetSideRef: _resolveExecutionTargetSide(
        move: move,
        opponentSlot: targetSlot,
      ),
      damage: damageResult.damage,
      didHit: true,
      didCrit: damageResult.didCrit,
      criticalMultiplier: damageResult.criticalMultiplier,
      stabMultiplier: damageResult.stabMultiplier,
      typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
    );

    return _ResolvedMoveExecution(
      attacker: postMoveConditions.attacker,
      defender: postMoveConditions.defender,
      field: postMoveConditions.field,
      rng: postMoveConditions.rng,
      execution: resolvedExecution,
      statusEvents: postMoveConditions.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(allVolatileEvents),
      fieldEvents: postMoveConditions.fieldEvents,
      timeline: _buildMoveTimeline(
        preExecutionVolatileEvents: preExecutionVolatileEvents,
        execution: resolvedExecution,
        statusEvents: postMoveConditions.statusEvents,
        fieldEvents: postMoveConditions.fieldEvents,
        postExecutionVolatileEvents: postMoveConditions.volatileEvents,
      ),
    );
  }

  _ResolvedHitCheck _resolveHitCheck({
    required BattleMove move,
    required BattleRng rng,
  }) {
    if (move.accuracy.isAlwaysHits || move.accuracy.value >= 100) {
      // Recadrage volontaire de BE4 :
      // - `alwaysHits` doit évidemment bypasser le hit check ;
      // - dans le moteur actuel, `percent(100)` est également déterministe,
      //   car nous n'avons encore ni accuracy stages, ni evasion, ni autres
      //   modificateurs de précision ;
      // - consommer du RNG sur 100% n'apporterait donc aucune vérité
      //   supplémentaire et compliquerait artificiellement les tests.
      return _ResolvedHitCheck(
        didHit: true,
        nextRng: rng,
      );
    }

    final roll = rng.nextPercentRoll();
    return _ResolvedHitCheck(
      didHit: roll.value <= move.accuracy.value,
      nextRng: roll.next,
    );
  }

  /// Résout la famille de cible observable d'une exécution.
  ///
  /// Phase G garde cette aide volontairement locale à la session :
  /// - elle évite de re-disperser la logique "combatant vs field" ;
  /// - elle ne transforme pas `BattleMoveTarget` en système de targeting riche ;
  /// - elle sert uniquement à produire un contrat d'exécution plus honnête.
  BattleMoveExecutionTargetKind _resolveExecutionTargetKind(
    BattleMove move,
  ) {
    return switch (move.target) {
      BattleMoveTarget.field => BattleMoveExecutionTargetKind.field,
      BattleMoveTarget.opponentSide => BattleMoveExecutionTargetKind.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        BattleMoveExecutionTargetKind.combatant,
    };
  }

  /// Résout le slot cible observable quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - en singles, `self` et `opponent` suffisent encore ;
  /// - `field` garde explicitement l'absence de slot ;
  /// - on n'anticipe ni doubles, ni targeting multiple, ni side targeting.
  BattleSlotRef? _resolveExecutionTargetSlot({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerSlot,
      BattleMoveTarget.field || BattleMoveTarget.opponentSide => null,
      BattleMoveTarget.opponent || BattleMoveTarget.unspecified => opponentSlot,
    };
  }

  BattleSideId? _resolveExecutionTargetSide({
    required BattleMove move,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.opponentSide => opponentSlot.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.field ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        null,
    };
  }

  /// Calcule les dégâts standards du moteur battle MVP enrichi.
  ///
  /// BE2 ne bascule toujours pas vers une formule Pokémon complète. Le but est
  /// maintenant plus honnête que l'ancien simple `damage = power` :
  /// - les dégâts standards reposent enfin sur un vrai snapshot de stats ;
  /// - les moves physiques utilisent `attack` vs `defense` ;
  /// - les moves spéciaux utilisent `specialAttack` vs `specialDefense` ;
  /// - les stages continuent à s'appliquer, mais sur ces vraies bases ;
  /// - `speed` influence désormais l'ordre d'action dans BE3, mais reste sans
  ///   rôle direct dans les dégâts.
  ///
  /// Frontière explicitement conservée :
  /// - pas d'accuracy/evasion stages ;
  /// - pas de règles Pokémon avancées de critique ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule ;
  /// - BE6 ajoute seulement :
  ///   - une vraie chance de critique minimale ;
  ///   - un multiplicateur critique fixe ;
  ///   - aucune interaction avancée avec stages / items / abilities.
  _ResolvedDamage _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleRng rng,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
        nextRng: rng,
      );
    }

    final offensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.attack,
      BattleMoveCategory.special => BattleStatId.specialAttack,
      BattleMoveCategory.status => BattleStatId.attack,
    };
    final defensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.defense,
      BattleMoveCategory.special => BattleStatId.specialDefense,
      BattleMoveCategory.status => BattleStatId.defense,
    };

    // Ordre de calcul volontairement documenté :
    // 1. on part du snapshot de stats résolu par le runtime ;
    // 2. on applique les stages côté attaquant et défenseur ;
    // 3. on utilise ensuite une formule entière simple, Pokémon-like ;
    // 4. on garde enfin un minimum de 1 dégât pour tout move non-status
    //    ayant passé le bridge BE1.
    final effectiveAttack = _resolveEffectiveStat(
      baseStat: _statValueFor(attacker.stats, offensiveStatId),
      multiplier: attacker.statStages.multiplierFor(offensiveStatId),
    );
    final effectiveDefense = _resolveEffectiveStat(
      baseStat: _statValueFor(defender.stats, defensiveStatId),
      multiplier: defender.statStages.multiplierFor(defensiveStatId),
    );
    final safePower = move.power < 0 ? 0 : move.power;
    final levelFactor = ((2 * attacker.level) ~/ 5) + 2;
    final baseDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();

    // BE5 ajoute ici la plus petite consommation honnête du type :
    // - STAB simple à 1.5 ;
    // - type chart standard ;
    // - immunité à 0 ;
    // - double type multiplicatif ;
    // - toujours aucune abilities, aucun item, aucune Tera ;
    // - BE9 n'ajoute ensuite qu'un unique modificateur météo local :
    //   la pluie pour Eau/Feu.
    final stabMultiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: move.type,
      attackerTyping: attacker.typing,
    );
    final typeEffectivenessMultiplier =
        BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: move.type,
      defenderTyping: defender.typing,
    );

    if (typeEffectivenessMultiplier == 0.0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
        nextRng: rng,
      );
    }

    // BE6 garde ici un ordre de résolution petit mais honnête :
    // 1. le hit check a déjà eu lieu en amont ;
    // 2. on vérifie ensuite l'immunité via le type chart ;
    // 3. seulement pour un hit offensif non immunisé, on résout un crit ;
    // 4. puis on applique STAB / efficacité de type et le clamp final.
    //
    // Ce choix évite de "dépenser" un tirage de crit sur un move qui n'aurait
    // de toute façon aucun effet. Pour le sous-ensemble actuel, c'est plus
    // honnête et reste mathématiquement neutre sur le résultat observable.
    final criticalHit = _resolveCriticalHit(
      move: move,
      rng: rng,
    );

    // Ordre de multiplication BE6 :
    // 1. baseDamage déterministe BE2 ;
    // 2. critique minimal BE6 ;
    // 3. malus de brûlure sur les moves physiques dans BE7 ;
    // 4. STAB ;
    // 5. effectiveness / résistance ;
    // 6. météo BE9 réellement supportée ;
    // 7. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final burnMultiplier = _conditionEngine.resolveStatusDamageMultiplier(
      move: move,
      attacker: attacker,
    );
    final weatherMultiplier = _conditionEngine.resolveFieldDamageMultiplier(
      move: move,
      field: field,
    );
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            burnMultiplier *
            stabMultiplier *
            typeEffectivenessMultiplier *
            weatherMultiplier)
        .floor();
    final finalDamage = scaledDamage < 1 ? 1 : scaledDamage;

    return _ResolvedDamage(
      damage: finalDamage,
      didCrit: criticalHit.didCrit,
      criticalMultiplier: criticalHit.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      nextRng: criticalHit.nextRng,
    );
  }

  _ResolvedCriticalHit _resolveCriticalHit({
    required BattleMove move,
    required BattleRng rng,
  }) {
    final chance = _critChanceForRatio(move.critRatio);
    if (chance.didOccurWithoutRng) {
      return _ResolvedCriticalHit(
        didCrit: true,
        multiplier: _criticalHitMultiplier,
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return _ResolvedCriticalHit(
      didCrit: roll.didOccur,
      multiplier: roll.didOccur ? _criticalHitMultiplier : 1.0,
      nextRng: roll.next,
    );
  }

  _CritChance _critChanceForRatio(int critRatio) {
    // Table BE6 volontairement explicite :
    // - on suit une lecture moderne Pokémon-like des stages de crit ;
    // - `1` reste le ratio neutre du canonique projet ;
    // - on ne prétend pas ouvrir Focus Energy, Lucky Chant ou d'autres
    //   modificateurs indirects.
    //
    // Mini-fix BE6 puis BE6-mini-fix-2 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide" ;
    // - le contrat public est désormais mieux verrouillé en amont, donc cette
    //   garde sert surtout de défense en profondeur pour un état incohérent
    //   qui réapparaîtrait à l'intérieur même de `map_battle` ;
    // - on préfère maintenant un `StateError` explicite, parce qu'à ce stade
    //   il s'agit d'un état battle incohérent, pas d'une simple option métier.
    if (critRatio < 1) {
      throw StateError(
        'Battle critical ratio must be >= 1; got $critRatio.',
      );
    }
    return switch (critRatio) {
      1 => const _CritChance(numerator: 1, denominator: 24),
      2 => const _CritChance(numerator: 1, denominator: 8),
      3 => const _CritChance(numerator: 1, denominator: 2),
      _ => const _CritChance.always(),
    };
  }

  int _statValueFor(BattleStatsSnapshot snapshot, BattleStatId stat) {
    return switch (stat) {
      BattleStatId.attack => snapshot.attack,
      BattleStatId.defense => snapshot.defense,
      BattleStatId.specialAttack => snapshot.specialAttack,
      BattleStatId.specialDefense => snapshot.specialDefense,
      BattleStatId.speed => snapshot.speed,
    };
  }

  int _resolveEffectiveSpeed(BattleCombatant combatant) {
    // L'ordre BE3 repose sur une vitesse effective déterministe :
    // - snapshot de speed résolu par le runtime ;
    // - multiplicateur de stages battle déjà présent ;
    // - Phase E délègue ensuite à l'engine conditionnel le malus simple de
    //   paralysie, pour arrêter de disperser cette règle métier ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    return _conditionEngine.resolveStatusAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
    );
  }

  int _resolveEffectiveStat({
    required int baseStat,
    required double multiplier,
  }) {
    // BE2 garde ici une règle simple et déterministe :
    // - pas de fraction stockée ;
    // - pas de rounding ambigu ;
    // - on applique les stages par multiplication, puis `floor` ;
    // - on clamp enfin au minimum 1 pour ne jamais diviser par 0 ni produire
    //   une stat offensive/défensive absurde.
    final resolved = (baseStat * multiplier).floor();
    return resolved < 1 ? 1 : resolved;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Politique BE10, volontairement petite et explicite :
  /// - les remplacements automatiques honnêtes ont déjà été tentés avant
  ///   d'entrer ici ;
  /// - si l'ennemi actif est encore K.O. à ce stade, il n'a plus de réserve
  ///   valide et le joueur gagne ;
  /// - sinon, si le joueur actif est encore K.O. mais qu'une réserve valide
  ///   existe encore, le combat continue pour laisser place au switch forcé ;
  /// - sinon, si le joueur actif est encore K.O., il n'a plus de réserve
  ///   valide et le joueur perd ;
  /// - sinon le combat continue ;
  /// - en cas de double K.O. sans réserve des deux côtés, on conserve donc la
  ///   politique historique "enemy d'abord", ce qui produit une victoire.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleSideState playerSide,
    BattleSideState enemySide,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemySide.active.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (playerSide.active.isFainted) {
      if (_firstUsableReserveIndex(playerSide.reserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }

  List<BattleTurnEvent> _buildMoveTimeline({
    List<BattleVolatileEvent> preExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
    BattleMoveExecution? execution,
    List<BattleStatusEvent> statusEvents = const <BattleStatusEvent>[],
    List<BattleFieldEvent> fieldEvents = const <BattleFieldEvent>[],
    List<BattleVolatileEvent> postExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
  }) {
    // BE10A garde une granularité volontairement petite :
    // - on ne reconstruit plus l'ordre en UI ;
    // - on fabrique ici une chronologie ordonnée au moment où le moteur
    //   connaît réellement l'enchaînement causal ;
    // - on ne descend toutefois pas dans une micro-chronologie Showdown-like
    //   de chaque sous-étape interne.
    final timeline = <BattleTurnEvent>[
      ..._turnEventsFromVolatile(preExecutionVolatileEvents),
      if (execution != null) BattleTurnExecutionEvent(execution),
      ..._turnEventsFromStatus(statusEvents),
      ..._turnEventsFromField(fieldEvents),
      ..._turnEventsFromVolatile(postExecutionVolatileEvents),
    ];
    return List<BattleTurnEvent>.unmodifiable(timeline);
  }

  List<BattleTurnEvent> _turnEventsFromStatus(
    Iterable<BattleStatusEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStatusEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromVolatile(
    Iterable<BattleVolatileEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnVolatileEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromField(
    Iterable<BattleFieldEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnFieldEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromStealthRock(
    Iterable<BattleStealthRockEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStealthRockEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromSpikes(
    Iterable<BattleSpikesEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnSpikesEvent.new),
    );
  }

  _ResolvedStealthRockMoveEffect? _resolveStealthRockMoveEffect({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsStealthRock || !didResolveHit) {
      return null;
    }

    if (targetSide.hasStealthRock) {
      return _ResolvedStealthRockMoveEffect(
        side: targetSide,
        events: <BattleStealthRockEvent>[
          BattleStealthRockEvent.alreadyPresent(
            side: targetSide.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStealthRockMoveEffect(
      side: targetSide.withStealthRock(true),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.set(
          side: targetSide.id,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedStealthRockEntry _resolveStealthRockEntry({
    required BattleSideState side,
  }) {
    if (!side.hasStealthRock) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final intendedDamage = resolveStealthRockEntryDamage(side.active);
    if (intendedDamage <= 0) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    final damagedActive = side.active.withDamage(actualDamage);

    return _ResolvedStealthRockEntry(
      side: side.withActive(damagedActive),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
        ),
      ],
    );
  }

  _ResolvedSpikesMoveEffect? _resolveSpikesMoveEffect({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsSpikes || !didResolveHit) {
      return null;
    }

    if (targetSide.spikesLayers >= 3) {
      return _ResolvedSpikesMoveEffect(
        side: targetSide,
        events: <BattleSpikesEvent>[
          BattleSpikesEvent.alreadyAtMaxLayers(
            side: targetSide.id,
            layers: targetSide.spikesLayers,
          ),
        ],
      );
    }

    final nextLayers = targetSide.spikesLayers + 1;
    return _ResolvedSpikesMoveEffect(
      side: targetSide.withSpikesLayers(nextLayers),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.setLayer(
          side: targetSide.id,
          layers: nextLayers,
        ),
      ],
    );
  }

  _ResolvedSpikesEntry _resolveSpikesEntry({
    required BattleSideState side,
  }) {
    if (side.spikesLayers <= 0) {
      return _ResolvedSpikesEntry(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final intendedDamage = resolveSpikesEntryDamage(
      combatant: side.active,
      layers: side.spikesLayers,
    );
    if (intendedDamage <= 0) {
      return _ResolvedSpikesEntry(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    final damagedActive = side.active.withDamage(actualDamage);

    return _ResolvedSpikesEntry(
      side: side.withActive(damagedActive),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
          layers: side.spikesLayers,
        ),
      ],
    );
  }

  _ResolvedEntryHazards _resolveEntryHazards({
    required BattleSideState side,
  }) {
    // H2 choisit ici la plus petite composition honnête :
    // - on ne crée pas de framework de hazards ;
    // - on compose seulement les deux mécaniques réellement supportées ;
    // - l'ordre est imposé et documenté : Stealth Rock puis Spikes ;
    // - si Stealth Rock met K.O. l'entrant, Spikes ne s'applique pas.
    final stealthRockResolution = _resolveStealthRockEntry(side: side);
    final sideAfterStealthRock = stealthRockResolution.side;
    if (sideAfterStealthRock.active.isFainted) {
      return _ResolvedEntryHazards(
        side: sideAfterStealthRock,
        stealthRockEvents: stealthRockResolution.events,
        spikesEvents: const <BattleSpikesEvent>[],
      );
    }

    final spikesResolution = _resolveSpikesEntry(side: sideAfterStealthRock);
    return _ResolvedEntryHazards(
      side: spikesResolution.side,
      stealthRockEvents: stealthRockResolution.events,
      spikesEvents: spikesResolution.events,
    );
  }
}

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.side,
    required this.action,
  });

  final BattleSideId side;
  final BattleAction action;
}

class _ResolvedBattleTurn {
  const _ResolvedBattleTurn({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.turnResult,
    required this.pendingTurn,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
  final _PendingTurnContinuation? pendingTurn;
}

final class _PendingTurnContinuation {
  const _PendingTurnContinuation({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.playerAction,
    required this.enemyAction,
    required this.turnTailScheduled,
    required this.remainingSteps,
    required this.executions,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.stealthRockEvents,
    required this.spikesEvents,
    required this.switchEvents,
    required this.timeline,
  });

  factory _PendingTurnContinuation.capture({
    required _QueuedTurnContext turn,
    required List<BattleQueueStep> remainingSteps,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return _PendingTurnContinuation(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      playerAction: playerAction,
      enemyAction: enemyAction,
      turnTailScheduled: turn.turnTailScheduled,
      remainingSteps: List<BattleQueueStep>.unmodifiable(remainingSteps),
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleAction playerAction;
  final BattleAction enemyAction;
  final bool turnTailScheduled;
  final List<BattleQueueStep> remainingSteps;
  final List<BattleMoveExecution> executions;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.execution,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.timeline,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedStealthRockMoveEffect {
  const _ResolvedStealthRockMoveEffect({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

class _ResolvedStealthRockEntry {
  const _ResolvedStealthRockEntry({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

class _ResolvedSpikesMoveEffect {
  const _ResolvedSpikesMoveEffect({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleSpikesEvent> events;
}

class _ResolvedSpikesEntry {
  const _ResolvedSpikesEntry({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleSpikesEvent> events;
}

class _ResolvedEntryHazards {
  const _ResolvedEntryHazards({
    required this.side,
    required this.stealthRockEvents,
    required this.spikesEvents,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedDamage {
  const _ResolvedDamage({
    required this.damage,
    required this.didCrit,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
    required this.nextRng,
  });

  final int damage;
  final bool didCrit;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;
  final BattleRng nextRng;

  bool get wasImmune => typeEffectivenessMultiplier == 0.0;
}

class _ResolvedCriticalHit {
  const _ResolvedCriticalHit({
    required this.didCrit,
    required this.multiplier,
    required this.nextRng,
  });

  final bool didCrit;
  final double multiplier;
  final BattleRng nextRng;
}

class _CritChance {
  const _CritChance({
    required this.numerator,
    required this.denominator,
  }) : didOccurWithoutRng = false;

  const _CritChance.always()
      : numerator = 1,
        denominator = 1,
        didOccurWithoutRng = true;

  final int numerator;
  final int denominator;
  final bool didOccurWithoutRng;
}

/// Contexte mutable strictement local à la consommation d'une queue de tour.
///
/// Phase F ne déplace pas la mutabilité vers `BattleState` :
/// - la session publique reste immutable ;
/// - ce contexte vit uniquement pendant `_resolveTurn` ;
/// - il sert à éviter de recopier manuellement le même faisceau de variables
///   `player/enemy/reserve/field/rng/events` dans chaque branche de queue.
final class _QueuedTurnContext {
  _QueuedTurnContext({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    this.originalPlayerAction,
    this.originalEnemyAction,
  });

  factory _QueuedTurnContext.resume(_PendingTurnContinuation pending) {
    return _QueuedTurnContext(
      playerSide: pending.playerSide,
      enemySide: pending.enemySide,
      field: pending.field,
      rng: pending.rng,
      originalPlayerAction: pending.playerAction,
      originalEnemyAction: pending.enemyAction,
    )
      ..turnTailScheduled = pending.turnTailScheduled
      ..executions.addAll(pending.executions)
      ..statusEvents.addAll(pending.statusEvents)
      ..volatileEvents.addAll(pending.volatileEvents)
      ..fieldEvents.addAll(pending.fieldEvents)
      ..stealthRockEvents.addAll(pending.stealthRockEvents)
      ..spikesEvents.addAll(pending.spikesEvents)
      ..switchEvents.addAll(pending.switchEvents)
      ..timeline.addAll(pending.timeline);
  }

  BattleSideState playerSide;
  BattleSideState enemySide;
  BattleFieldState field;
  BattleRng rng;
  BattleAction? originalPlayerAction;
  BattleAction? originalEnemyAction;
  bool turnTailScheduled = false;
  _PendingTurnContinuation? pendingTurn;

  final List<BattleMoveExecution> executions = <BattleMoveExecution>[];
  final List<BattleStatusEvent> statusEvents = <BattleStatusEvent>[];
  final List<BattleVolatileEvent> volatileEvents = <BattleVolatileEvent>[];
  final List<BattleFieldEvent> fieldEvents = <BattleFieldEvent>[];
  final List<BattleStealthRockEvent> stealthRockEvents =
      <BattleStealthRockEvent>[];
  final List<BattleSpikesEvent> spikesEvents = <BattleSpikesEvent>[];
  final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
  final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];

  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }

  void updateSide(BattleSideId sideId, BattleSideState sideState) {
    switch (sideId) {
      case BattleSideId.player:
        playerSide = sideState;
      case BattleSideId.enemy:
        enemySide = sideState;
    }
  }

  void updateActive(BattleSideId sideId, BattleCombatant active) {
    final existingSide = side(sideId);
    updateSide(
      sideId,
      existingSide.withActiveAndReserve(
        active: active,
        reserve: existingSide.reserve,
      ),
    );
  }
}

```


### packages/map_battle/test/battle_decision_request_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

void main() {
  group('BattleSession Phase C decision requests', () {
    test('a free turn exposes a turn choice request with moves and switches',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleTurnChoiceRequest>());
      final turnChoiceRequest = request as BattleTurnChoiceRequest;
      expect(turnChoiceRequest.actor, equals(BattleDecisionActor.player));
      expect(turnChoiceRequest.side, equals(BattleSideId.player));
      expect(
        turnChoiceRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(turnChoiceRequest.moveChoices, hasLength(1));
      expect(turnChoiceRequest.switchChoices, hasLength(1));
      expect(turnChoiceRequest.captureChoice, isA<PlayerBattleChoiceCapture>());
      expect(turnChoiceRequest.runChoice, isA<PlayerBattleChoiceRun>());
    });

    test('a fainted active with a reserve exposes a forced replacement request',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleForcedReplacementRequest>());
      final forcedReplacementRequest =
          request as BattleForcedReplacementRequest;
      expect(forcedReplacementRequest.side, equals(BattleSideId.player));
      expect(
        forcedReplacementRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        forcedReplacementRequest.reason,
        equals(BattleForcedReplacementReason.activeFainted),
      );
      expect(forcedReplacementRequest.switchChoices, hasLength(1));
      expect(
        forcedReplacementRequest.allowedChoices.single,
        isA<PlayerBattleChoiceSwitch>(),
      );
    });

    test('a forced recharge exposes a continue request with an explicit reason',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleContinueRequest>());
      final continueRequest = request as BattleContinueRequest;
      expect(continueRequest.side, equals(BattleSideId.player));
      expect(
        continueRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        continueRequest.reason,
        equals(BattleContinueReason.mustRecharge),
      );
      expect(continueRequest.allowedChoices, hasLength(1));
      expect(continueRequest.allowedChoices.single,
          isA<PlayerBattleChoiceContinue>());
    });

    test(
        'a battler with no usable move and no other legal choice exposes an explicit wait request',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleWaitRequest>());
      final waitRequest = request as BattleWaitRequest;
      expect(waitRequest.side, equals(BattleSideId.player));
      expect(
        waitRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(waitRequest.reason, equals(BattleWaitReason.noLegalChoice));
      expect(waitRequest.allowedChoices, isEmpty);
    });

    test('request constructors reject mismatched side and slot attachments',
        () {
      expect(
        () => BattleContinueRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reason: BattleContinueReason.mustRecharge,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleWaitRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef(
            side: BattleSideId.player,
            slotIndex: 1,
          ),
          reason: BattleWaitReason.noLegalChoice,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an illegal choice for the current request kind is rejected cleanly',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('forcedReplacement'),
          ),
        ),
      );
    });

    test('request transitions remain coherent across a forced continue turn',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(session.decisionRequest, isA<BattleContinueRequest>());

      final afterContinue =
          session.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterContinue.decisionRequest, isA<BattleTurnChoiceRequest>());
    });

    test('a finished battle exposes an explicit wait request', () {
      final session = _session(
        player: _combatant(
          speciesId: 'player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 200,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          maxHp: 1,
          currentHp: 1,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final finishedSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(finishedSession.state.isFinished, isTrue);
      expect(finishedSession.decisionRequest, isA<BattleWaitRequest>());
      expect(
        (finishedSession.decisionRequest as BattleWaitRequest).reason,
        equals(BattleWaitReason.battleFinished),
      );
    });
  });
}

```


### packages/map_battle/test/battle_session_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _neutralBattleStats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
      bool allowCapture = false,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test(
        'createBattleSession preserves the additional honest battle contract fields transported by BE1 through BE9',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(primaryType: 'electric'),
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: const [
            BattleMoveData(
              id: 'protect',
              name: 'Protect',
              power: 0,
              type: 'normal',
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              accuracy: BattleMoveAccuracy.alwaysHits(),
              pp: 10,
              currentPp: 7,
              priority: 1,
              critRatio: 2,
              selfVolatileStatus: BattleVolatileStatusId.protect,
            ),
            BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              type: 'normal',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 5,
              currentPp: 3,
              requiresRecharge: true,
            ),
            BattleMoveData(
              id: 'solar_beam',
              name: 'Solar Beam',
              power: 120,
              type: 'grass',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 10,
              currentPp: 9,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'solar_charge',
              ),
            ),
            BattleMoveData(
              id: 'feint',
              name: 'Feint',
              power: 30,
              type: 'normal',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              breaksProtect: true,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(
            primaryType: 'water',
            secondaryType: 'ice',
          ),
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'tackle',
              chargeStateId: 'stored_charge',
            ),
          ),
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 2,
          ),
        ),
      );

      final session = createBattleSession(setup);
      final protect = session.state.player.moves[0];
      final hyperBeam = session.state.player.moves[1];
      final solarBeam = session.state.player.moves[2];
      final feint = session.state.player.moves[3];
      final playerTyping = session.state.player.typing!;
      final enemyTyping = session.state.enemy.typing!;

      expect(protect.type, equals('normal'));
      expect(protect.category, equals(BattleMoveCategory.status));
      expect(protect.target, equals(BattleMoveTarget.self));
      expect(protect.accuracy.kind, equals(BattleMoveAccuracyKind.alwaysHits));
      expect(protect.pp, equals(10));
      expect(protect.currentPp, equals(7));
      expect(protect.priority, equals(1));
      expect(protect.critRatio, equals(2));
      expect(
        protect.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(hyperBeam.requiresRecharge, isTrue);
      expect(solarBeam.chargeThenStrikeEffect?.chargeStateId,
          equals('solar_charge'));
      expect(feint.breaksProtect, isTrue);
      expect(playerTyping.primaryType, equals('electric'));
      expect(playerTyping.secondaryType, isNull);
      expect(enemyTyping.primaryType, equals('water'));
      expect(enemyTyping.secondaryType, equals('ice'));
      expect(session.state.player.volatileState.mustRecharge, isTrue);
      expect(
        session.state.enemy.volatileState.pendingCharge?.moveId,
        equals('tackle'),
      );
      expect(session.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(session.state.field.weather?.remainingTurns, equals(3));
      expect(
        session.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(session.state.field.pseudoWeather?.remainingTurns, equals(2));
    });

    test(
        'createBattleSession preserves an explicit major status seed and move status effect',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          majorStatus: const BattleMajorStatusState.brn(),
          moves: const [
            BattleMoveData(
              id: 'thunder_wave',
              name: 'Thunder Wave',
              power: 0,
              category: BattleMoveCategory.status,
              majorStatusEffect: BattleMoveMajorStatusEffect(
                status: BattleMajorStatusId.par,
              ),
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.majorStatus?.id,
          equals(BattleMajorStatusId.brn));
      expect(
        session.state.player.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test('createBattleSession preserves reserves and stable lineup identities',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        playerReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            level: 5,
            maxHp: 22,
            currentHp: 18,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        enemyPokemon: BattleCombatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyReservePokemon: const <BattleCombatantData>[
          BattleCombatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            level: 5,
            maxHp: 24,
            stats: _neutralBattleStats,
            moves: <BattleMoveData>[
              BattleMoveData(id: 'growl', name: 'Growl', power: 0),
            ],
          ),
        ],
        isTrainerBattle: true,
        trainerId: 'trainer-reserve',
      );

      final session = createBattleSession(setup);

      expect(session.state.player.lineupIndex, equals(0));
      expect(session.state.playerReserve.single.lineupIndex, equals(1));
      expect(session.state.playerReserve.single.currentHp, equals(18));
      expect(session.state.enemy.lineupIndex, equals(0));
      expect(session.state.enemyReserve.single.lineupIndex, equals(1));
    });

    test('BattleMoveData rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMoveData(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMove rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMove(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMoveData keeps a valid crit ratio unchanged', () {
      // Mini-fix BE6-2 :
      // - on supprime les faux tests qui contournaient le contrat par héritage ;
      // - le vrai contrat public doit maintenant être évalué tel qu'il est
      //   réellement exposé aux call sites : un DTO final, `const`, typé ;
      // - ce test vérifie simplement qu'une valeur valide reste stable.
      const move = BattleMoveData(
        id: 'slash',
        name: 'Slash',
        power: 50,
        critRatio: 2,
      );

      expect(move.critRatio, equals(2));
    });

    test('BattleMove.withConsumedPp preserves a valid crit ratio', () {
      // Ce test remplace honnêtement l'ancien scénario artificiel :
      // - on ne forge plus un move malformé via override ;
      // - on vérifie que le vrai contrat public battle conserve `critRatio`
      //   pendant une transition d'état normale du moteur.
      const move = BattleMove(
        id: 'slash',
        name: 'Slash',
        power: 50,
        pp: 10,
        currentPp: 3,
        critRatio: 3,
      );

      final consumed = move.withConsumedPp();

      expect(consumed.critRatio, equals(3));
      expect(consumed.currentPp, equals(2));
    });

    test('getAvailableChoices hides fight choices whose currentPp is zero', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
            BattleMoveData(
              id: 'scratch',
              name: 'Griffe',
              power: 4,
              pp: 10,
              currentPp: 3,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();
      final fightChoices =
          choices.whereType<PlayerBattleChoiceFight>().toList();

      expect(fightChoices, hasLength(1));
      expect(fightChoices.single.moveIndex, equals(1));
    });

    test('forcing a move with zero PP is rejected explicitly', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('n’a plus de PP'),
          ),
        ),
      );
    });

    test(
        'enemy with no configured move fails explicitly instead of masquerading as a run action',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('aucun move configuré'),
          ),
        ),
      );
    });

    test(
        'enemy with only zero-PP moves fails explicitly while Struggle stays out of scope',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Struggle est hors scope'),
          ),
        ),
      );
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices exposes capture in wild battle when allowed', () {
      final setup = createTestSetup(allowCapture: true);
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(4));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceCapture>());
      expect(choices[3], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('getAvailableChoices does not expose capture in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
        allowCapture: true,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('getAvailableChoices exposes Continue for a forced recharge turn', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 5,
            maxHp: 20,
            stats: _neutralBattleStats,
            volatileState: const BattleVolatileState(
              mustRecharge: true,
            ),
            moves: const [
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 150,
                requiresRecharge: true,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'lapras',
            level: 5,
            maxHp: 25,
            stats: _neutralBattleStats,
            moves: const [
              BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices, hasLength(1));
      expect(choices.single, isA<PlayerBattleChoiceContinue>());
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Avec le contract de dégâts BE2, le move passe maintenant par les
      // vraies stats résolues au lieu de faire `damage = power`.
      expect(newSession.state.enemy.currentHp, equals(23));
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Même logique pour la contre-attaque : on attend désormais un dégât
      // déterministe issu de la formule BE2, pas la puissance brute.
      expect(newSession.state.player.currentHp, equals(18));
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 100,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(
        setup,
        rng: BattleScriptedRng(List<int>.filled(6, 2)),
      );

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}

```


### packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart

```dart
import 'package:map_core/map_core.dart';

import '../models/pokemon_project_data_models.dart';

/// Version logique du seed embarqué des moves bootstrap.
///
/// On ne crée pas ici un nouveau schéma JSON ni un framework de seed générique.
/// La "version" utile pour ce lot est simplement :
/// - un entier local, facile à relire dans le code ;
/// - reporté aussi dans les notes du catalogue seedé ;
/// - assez simple pour tracer les évolutions sans rouvrir `PokemonDataMeta`.
const int embeddedPokemonMovesSeedVersion = 1;

/// Construit le catalogue `moves` embarqué pour le bootstrap projet.
///
/// Choix d'architecture volontaire :
/// - le seed est codé en Dart, pas en asset Flutter ;
/// - le bootstrap n'a donc ni dépendance `rootBundle`, ni dépendance réseau ;
/// - le seed passe par les vrais modèles canoniques `PokemonMove`, puis
///   sérialise `toJson()` ;
/// - la copie dans le projet reste un simple write JSON, sans génération live.
///
/// Pourquoi pas un asset JSON pour M4 :
/// - `map_editor` ne versionne pas déjà ce type de seed via `flutter/assets` ;
/// - le use case d'initialisation est aujourd'hui un seam applicatif simple,
///   testable sans plomberie Flutter ;
/// - ajouter une lecture d'asset ici ouvrirait une couche de packaging plus
///   large que nécessaire pour ce seul lot.
///
/// Pourquoi pas le catalogue Showdown complet :
/// - cela demanderait soit du tooling de génération versionné, soit un gros
///   artefact généré hors scope M4 ;
/// - M4 doit fixer le seam bootstrap, pas ouvrir un chantier "catalog dump".
///
/// Le seed reste donc volontairement :
/// - canonique ;
/// - offline ;
/// - substantiel ;
/// - mais encore curaté.
PokemonCatalogFile buildEmbeddedPokemonMovesBootstrapSeed() {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: const PokemonDataMeta(
      description: 'Move catalog for the local Pokemon project database.',
      sourcePriority: <String>['internal'],
      notes: <String>[
        'Embedded canonical move seed shipped with map_editor for offline bootstrap.',
        'Curated from Showdown-backed move data and versioned in the repository.',
        'bootstrap_seed_version:$embeddedPokemonMovesSeedVersion',
      ],
    ),
    entries: _embeddedPokemonMovesSeedEntries
        .map((move) => move.toJson())
        .toList(growable: false),
  );
}

/// Le seed n'essaie pas d'être tout Showdown.
///
/// On prend un sous-ensemble volontairement utile pour un projet frais :
/// - attaques simples courantes ;
/// - quelques statuts et boosts ;
/// - quelques moves plus "structurels" pour garder des entrées qui montrent
///   honnêtement les limites actuelles (`catalog_only` quand nécessaire).
final List<PokemonMove> _embeddedPokemonMovesSeedEntries = <PokemonMove>[
  ..._structuredSupportedSeedMoves,
  ..._catalogOnlySeedMoves,
];

/// Moves dont la structure utile est déjà correctement portée par le modèle.
///
/// Même si `map_battle` ne consomme pas encore tout cela, le modèle canonique
/// est capable de les décrire sans mensonge métier majeur.
final List<PokemonMove> _structuredSupportedSeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'absorb',
    showdownMoveId: 'absorb',
    name: 'Absorb',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 20,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.drain(numerator: 1, denominator: 2),
    ],
    shortDescription: 'User recovers 50% of the damage dealt.',
    description:
        'The user recovers 1/2 the HP lost by the target, rounded half up. '
        'If Big Root is held by the user, the HP recovered is 1.3x normal, '
        'rounded half down.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:drain',
    ],
  ),
  _showdownSeedMove(
    id: 'double_slap',
    showdownMoveId: 'doubleslap',
    name: 'Double Slap',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 15,
    accuracy: const PokemonMoveAccuracy.percent(value: 85),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.multiHit(minHits: 2, maxHits: 5),
    ],
    shortDescription: 'Hits 2-5 times in one turn.',
    description:
        'Hits two to five times. Has a 35% chance to hit two or three times '
        'and a 15% chance to hit four or five times. If one of the hits '
        'breaks the target\'s substitute, it will take damage for the '
        'remaining hits. If the user has the Skill Link Ability, this move '
        'will always hit five times.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:multi_hit',
    ],
  ),
  // Phase B ajoute ici un seul lift bootstrap borné :
  // - des moves très fréquents en début de jeu ;
  // - déjà absorbés honnêtement par le bridge et le moteur ;
  // - choisis pour améliorer la battleability d'un scaffold frais sans ouvrir
  //   de nouvelle mécanique ni reclassifier artificiellement un seam limite.
  _showdownSeedMove(
    id: 'ember',
    showdownMoveId: 'ember',
    name: 'Ember',
    generation: 1,
    type: 'fire',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'brn'),
    ],
    shortDescription: '10% chance to burn the target.',
    description: 'Has a 10% chance to burn the target.',
  ),
  _showdownSeedMove(
    id: 'feint',
    showdownMoveId: 'feint',
    name: 'Feint',
    generation: 4,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 30,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    priority: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.breakProtect(),
    ],
    shortDescription: 'Nullifies Detect, Protect, and Quick/Wide Guard.',
    description: 'If this move is successful, it breaks through the target\'s '
        'Baneful Bunker, Detect, King\'s Shield, Protect, or Spiky Shield for '
        'this turn, allowing other Pokemon to attack the target normally. '
        'If the target\'s side is protected by Crafty Shield, Mat Block, '
        'Quick Guard, or Wide Guard, that protection is also broken for this '
        'turn and other Pokemon may attack the target\'s side normally.',
  ),
  _showdownSeedMove(
    id: 'growl',
    showdownMoveId: 'growl',
    name: 'Growl',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 40,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.sound,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Attack by 1.',
    description: 'Lowers the target\'s Attack by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'hyper_beam',
    showdownMoveId: 'hyperbeam',
    name: 'Hyper Beam',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    basePower: 150,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.recharge,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.requireRecharge(),
    ],
    shortDescription: 'User cannot move next turn.',
    description:
        'If this move is successful, the user must recharge on the following '
        'turn and cannot select a move.',
  ),
  _showdownSeedMove(
    id: 'leer',
    showdownMoveId: 'leer',
    name: 'Leer',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'quick_attack',
    showdownMoveId: 'quickattack',
    name: 'Quick Attack',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    priority: 1,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'Usually goes first.',
    description:
        'Nearly always goes first. No additional effect in the local subset.',
  ),
  _showdownSeedMove(
    id: 'rain_dance',
    showdownMoveId: 'raindance',
    name: 'Rain Dance',
    generation: 2,
    type: 'water',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setWeather(weatherId: 'raindance'),
    ],
    shortDescription: 'For 5 turns, heavy rain powers Water moves.',
    description: 'For 5 turns, the weather becomes Rain Dance. The damage of '
        'Water-type attacks is multiplied by 1.5 and the damage of Fire-type '
        'attacks is multiplied by 0.5 during the effect. Lasts for 8 turns if '
        'the user is holding Damp Rock. Fails if the current weather is Rain '
        'Dance.',
  ),
  _showdownSeedMove(
    id: 'razor_leaf',
    showdownMoveId: 'razorleaf',
    name: 'Razor Leaf',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 55,
    accuracy: const PokemonMoveAccuracy.percent(value: 95),
    pp: 25,
    critRatio: 2,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.slicing,
    ],
    shortDescription: 'High critical hit ratio. Hits adjacent foes.',
    description: 'Has a higher chance for a critical hit.',
  ),
  _showdownSeedMove(
    id: 'scratch',
    showdownMoveId: 'scratch',
    name: 'Scratch',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'swords_dance',
    showdownMoveId: 'swordsdance',
    name: 'Swords Dance',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.dance,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        targetScope: PokemonMoveEffectTargetScope.self,
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.attack,
            stages: 2,
          ),
        ],
      ),
    ],
    shortDescription: 'Raises the user\'s Attack by 2.',
    description: 'Raises the user\'s Attack by 2 stages.',
  ),
  _showdownSeedMove(
    id: 'swift',
    showdownMoveId: 'swift',
    name: 'Swift',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.special,
    target: PokemonMoveTarget.allAdjacentFoes,
    basePower: 60,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'This move does not check accuracy. Hits foes.',
    description: 'This move does not check accuracy.',
  ),
  _showdownSeedMove(
    id: 'tackle',
    showdownMoveId: 'tackle',
    name: 'Tackle',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.physical,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 35,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'tail_whip',
    showdownMoveId: 'tailwhip',
    name: 'Tail Whip',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.allAdjacentFoes,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 30,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.modifyStats(
        stageChanges: <PokemonMoveStatStageChange>[
          PokemonMoveStatStageChange(
            stat: PokemonMoveStatId.defense,
            stages: -1,
          ),
        ],
      ),
    ],
    shortDescription: 'Lowers the foe(s) Defense by 1.',
    description: 'Lowers the target\'s Defense by 1 stage.',
  ),
  _showdownSeedMove(
    id: 'thunder_wave',
    showdownMoveId: 'thunderwave',
    name: 'Thunder Wave',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.percent(value: 90),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(statusId: 'par'),
    ],
    shortDescription: 'Paralyzes the target.',
    description:
        'Paralyzes the target. This move does not ignore type immunity.',
  ),
  _showdownSeedMove(
    id: 'thunderbolt',
    showdownMoveId: 'thunderbolt',
    name: 'Thunderbolt',
    generation: 1,
    type: 'electric',
    category: PokemonMoveCategory.special,
    basePower: 90,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 15,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.applyStatus(chance: 10, statusId: 'par'),
    ],
    shortDescription: '10% chance to paralyze the target.',
    description: 'Has a 10% chance to paralyze the target.',
  ),
  _showdownSeedMove(
    id: 'u_turn',
    showdownMoveId: 'uturn',
    name: 'U-turn',
    generation: 4,
    type: 'bug',
    category: PokemonMoveCategory.physical,
    basePower: 70,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.selfSwitch(),
    ],
    shortDescription: 'User switches out after damaging the target.',
    description:
        'If this move is successful and the user has not fainted, the user '
        'switches out even if it is trapped and is replaced immediately by a '
        'selected party member. The user does not switch out if there are no '
        'unfainted party members, or if the target switched out using an '
        'Eject Button or through the effect of the Emergency Exit or Wimp Out '
        'Abilities.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:self_switch',
    ],
  ),
  _showdownSeedMove(
    id: 'vine_whip',
    showdownMoveId: 'vinewhip',
    name: 'Vine Whip',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.physical,
    basePower: 45,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.contact,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  _showdownSeedMove(
    id: 'water_gun',
    showdownMoveId: 'watergun',
    name: 'Water Gun',
    generation: 1,
    type: 'water',
    category: PokemonMoveCategory.special,
    basePower: 40,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 25,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.protect,
    ],
    shortDescription: 'No additional effect.',
    description: 'No additional effect.',
  ),
  // R1 réaligne ici trois entrées que le dépôt supporte déjà honnêtement :
  // - `stealth_rock` et `spikes` sont supportés de bout en bout depuis H1/H2 ;
  // - `trick_room` est réellement consommé par le moteur local sur le sous-
  //   ensemble seed/bridge/runtime actuellement ouvert ;
  // - on les remonte donc dans la section structurée au lieu de les laisser
  //   dans un regroupement historique devenu trompeur.
  _showdownSeedMove(
    id: 'stealth_rock',
    showdownMoveId: 'stealthrock',
    name: 'Stealth Rock',
    generation: 4,
    type: 'rock',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mustPressure,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
    ],
    shortDescription: 'Hurts foes on switch-in. Factors Rock weakness.',
    description:
        'Sets up a hazard on the opposing side of the field, damaging each '
        'opposing Pokemon that switches in. Fails if the effect is already '
        'active on the opposing side. Foes lose 1/32, 1/16, 1/8, 1/4, or 1/2 '
        'of their maximum HP, rounded down, based on their weakness to the '
        'Rock type; 0.25x, 0.5x, neutral, 2x, or 4x, respectively. Can be '
        'removed from the opposing side if any Pokemon uses Tidy Up, or if '
        'any opposing Pokemon uses Mortal Spin, Rapid Spin, or Defog '
        'successfully, or is hit by Defog.',
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'spikes',
    showdownMoveId: 'spikes',
    name: 'Spikes',
    generation: 2,
    type: 'ground',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.foeSide,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.reflectable,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSideCondition(conditionId: 'spikes'),
    ],
    shortDescription: 'Adds a layer of grounded entry hazard on the foe side.',
    description:
        'Sets Spikes on the opposing side. Up to three layers can be active. '
        'Grounded foes that switch in lose 1/8, 1/6, or 1/4 of their maximum '
        'HP depending on whether one, two, or three layers are present. Does '
        'nothing if three layers are already active. Additional immunities and '
        'hazard removal remain outside the local subset.',
    showdownHooksPresent: <String>[
      'condition.onSideStart',
      'condition.onSwitchIn',
    ],
  ),
  _showdownSeedMove(
    id: 'trick_room',
    showdownMoveId: 'trickroom',
    name: 'Trick Room',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 5,
    priority: -7,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setPseudoWeather(pseudoWeatherId: 'trickroom'),
    ],
    shortDescription: 'Goes last. For 5 turns, turn order is reversed.',
    description:
        'For 5 turns, the Speed of every Pokemon is recalculated for the '
        'purposes of determining turn order. During the effect, each '
        'Pokemon\'s Speed is considered to be (10000 - its normal Speed), and '
        'if this value is greater than 8191, 8192 is subtracted from it. If '
        'this move is used during the effect, the effect ends.',
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onFieldEnd',
      'condition.onFieldRestart',
      'condition.onFieldStart',
    ],
  ),
  _showdownSeedMove(
    id: 'whirlwind',
    showdownMoveId: 'whirlwind',
    name: 'Whirlwind',
    generation: 1,
    type: 'normal',
    category: PokemonMoveCategory.status,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 20,
    priority: -6,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.allyAnim,
      PokemonMoveFlag.bypassSubstitute,
      PokemonMoveFlag.failCopycat,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noAssist,
      PokemonMoveFlag.reflectable,
      PokemonMoveFlag.wind,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.forceSwitch(),
    ],
    shortDescription: 'Forces the target to switch to a random ally.',
    description:
        'The target is forced to switch out and be replaced with a random '
        'unfainted ally. Fails if the target is the last unfainted Pokemon in '
        'its party, or if the target used Ingrain previously or has the '
        'Suction Cups Ability.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'unsupported_effect_kind:force_switch',
    ],
  ),
];

/// Moves volontairement gardés dans le seed malgré un support encore limité.
///
/// On les garde parce qu'ils rendent le seed plus utile qu'une simple liste
/// d'attaques triviales, tout en exposant honnêtement les limites structurelles
/// actuelles via `catalog_only` et `unsupportedReasons`.
final List<PokemonMove> _catalogOnlySeedMoves = <PokemonMove>[
  _showdownSeedMove(
    id: 'electric_terrain',
    showdownMoveId: 'electricterrain',
    name: 'Electric Terrain',
    generation: 6,
    type: 'electric',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.all,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.nonSky,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setTerrain(terrainId: 'electricterrain'),
    ],
    shortDescription: '5 turns. Grounded: +Electric power, can\'t sleep.',
    description:
        'For 5 turns, the terrain becomes Electric Terrain. During the '
        'effect, the power of Electric-type attacks made by grounded Pokemon '
        'is multiplied by 1.3 and grounded Pokemon cannot fall asleep; Pokemon '
        'already asleep do not wake up. Grounded Pokemon cannot become '
        'affected by Yawn or fall asleep from its effect. Camouflage '
        'transforms the user into an Electric type, Nature Power becomes '
        'Thunderbolt, and Secret Power has a 30% chance to cause paralysis. '
        'Fails if the current terrain is Electric Terrain.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onBasePower',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldStart',
      'showdown_callback:condition.onSetStatus',
      'showdown_callback:condition.onTryAddVolatile',
      'unsupported_mechanic:condition',
    ],
    showdownHooksPresent: <String>[
      'condition.durationCallback',
      'condition.onBasePower',
      'condition.onFieldEnd',
      'condition.onFieldStart',
      'condition.onSetStatus',
      'condition.onTryAddVolatile',
    ],
  ),
  _showdownSeedMove(
    id: 'healing_wish',
    showdownMoveId: 'healingwish',
    name: 'Healing Wish',
    generation: 4,
    type: 'psychic',
    category: PokemonMoveCategory.status,
    target: PokemonMoveTarget.self,
    accuracy: const PokemonMoveAccuracy.alwaysHits(),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.heal,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.snatch,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.setSlotCondition(conditionId: 'healingwish'),
    ],
    shortDescription: 'User faints. Next hurt Pokemon is fully healed.',
    description:
        'The user faints, and if the Pokemon brought out to replace it does '
        'not have full HP or has a non-volatile status condition, its HP is '
        'fully restored along with having any non-volatile status condition '
        'cured. The replacement is sent out at the end of the turn, and the '
        'healing happens before hazards take effect. This effect continues '
        'until a Pokemon that meets either of these conditions switches in at '
        'the user\'s position or gets swapped into the position with Ally '
        'Switch. Fails if the user is the last unfainted Pokemon in its party.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:condition.onSwap',
      'showdown_callback:condition.onSwitchIn',
      'showdown_callback:onTryHit',
      'unsupported_mechanic:condition',
      'unsupported_mechanic:selfdestruct',
    ],
    showdownHooksPresent: <String>[
      'condition.onSwap',
      'condition.onSwitchIn',
      'onTryHit',
    ],
  ),
  _showdownSeedMove(
    id: 'solar_beam',
    showdownMoveId: 'solarbeam',
    name: 'Solar Beam',
    generation: 1,
    type: 'grass',
    category: PokemonMoveCategory.special,
    basePower: 120,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    pp: 10,
    flags: <PokemonMoveFlag>[
      PokemonMoveFlag.charge,
      PokemonMoveFlag.failInstruct,
      PokemonMoveFlag.metronome,
      PokemonMoveFlag.mirror,
      PokemonMoveFlag.noSleepTalk,
      PokemonMoveFlag.protect,
    ],
    effects: const <PokemonMoveEffect>[
      PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
    ],
    shortDescription: 'Charges turn 1. Hits turn 2. No charge in sunlight.',
    description:
        'This attack charges on the first turn and executes on the second. '
        'Power is halved if the weather is Primordial Sea, Rain Dance, '
        'Sandstorm, or Snow and the user is not holding Utility Umbrella. If '
        'the user is holding a Power Herb or the weather is Desolate Land or '
        'Sunny Day, the move completes in one turn. If the user is holding '
        'Utility Umbrella and the weather is Desolate Land or Sunny Day, the '
        'move still requires a turn to charge.',
    engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
    unsupportedReasons: <String>[
      'showdown_callback:onBasePower',
      'showdown_callback:onTryMove',
      'unsupported_mechanic:weather_charge_shortcuts',
    ],
    showdownHooksPresent: <String>[
      'onBasePower',
      'onTryMove',
    ],
  ),
];

/// Helper unique pour garder le seed compact sans créer de framework.
///
/// `source` vaut volontairement `showdown` :
/// - il décrit l'origine du contenu métier ;
/// - pas le mode de chargement ;
/// - le bootstrap reste local/offline car ce seed est déjà versionné ici.
PokemonMove _showdownSeedMove({
  required String id,
  required String showdownMoveId,
  required String name,
  required int generation,
  required String type,
  required PokemonMoveCategory category,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int basePower = 0,
  required PokemonMoveAccuracy accuracy,
  int pp = 0,
  bool noPpBoosts = false,
  int priority = 0,
  int critRatio = 1,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  String shortDescription = '',
  String description = '',
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
  List<String> showdownHooksPresent = const <String>[],
}) {
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: generation,
    source: 'showdown',
    type: type,
    category: category,
    target: target,
    basePower: basePower,
    accuracy: accuracy,
    pp: pp,
    noPpBoosts: noPpBoosts,
    priority: priority,
    critRatio: critRatio,
    flags: flags,
    effects: effects,
    shortDescription: shortDescription,
    description: description,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
    sourceRefs: PokemonMoveSourceRefs(
      showdownMoveId: showdownMoveId,
      showdownHooksPresent: showdownHooksPresent,
    ),
  ).normalized();
}

```


### packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

void main() {
  group('buildEmbeddedPokemonMovesBootstrapSeed', () {
    late Map<String, PokemonMove> movesById;

    setUp(() {
      final catalog = buildEmbeddedPokemonMovesBootstrapSeed();
      movesById = <String, PokemonMove>{
        for (final entry in catalog.entries)
          PokemonMove.fromJson(entry).id: PokemonMove.fromJson(entry),
      };
    });

    test(
        'keeps obviously unsupported switch and multi-hit seams out of supported bootstrap claims',
        () {
      expect(
        movesById['absorb']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['double_slap']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['u_turn']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['whirlwind']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
    });

    test('reflects the real BE8, BE9, H1, and H2 support that now exists locally',
        () {
      expect(
        movesById['solar_beam']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.catalogOnly),
      );
      expect(
        movesById['trick_room']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['stealth_rock']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
    });

    test(
        'adds only bootstrap entries that are already honestly supported by the bridge and battle engine',
        () {
      expect(
        movesById['scratch']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['tail_whip']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['ember']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['water_gun']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['quick_attack']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );
      expect(
        movesById['spikes']!.engineSupportLevel,
        equals(PokemonMoveEngineSupportLevel.structuredSupported),
      );

      // On verrouille quelques détails métier pour éviter un faux lift :
      // - `quick_attack` doit rester un vrai move de priorité ;
      // - `tail_whip` doit rester une vraie baisse déterministe de Défense ;
      // - `ember` ne doit pas perdre sa petite chance de brûlure.
      expect(movesById['quick_attack']!.priority, equals(1));
      expect(
        movesById['tail_whip']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (_) => null,
              applyVolatileStatus: (_) => null,
              modifyStats: (effect) => effect.stageChanges.single.stages,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(-1),
      );
      expect(
        movesById['ember']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (effect) => effect.chance,
              applyVolatileStatus: (_) => null,
              modifyStats: (_) => null,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (_) => null,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals(10),
      );
      expect(
        movesById['spikes']!.effects.single.map(
              fixedDamage: (_) => null,
              multiHit: (_) => null,
              applyStatus: (_) => null,
              applyVolatileStatus: (_) => null,
              modifyStats: (_) => null,
              heal: (_) => null,
              drain: (_) => null,
              recoil: (_) => null,
              requireRecharge: (_) => null,
              chargeThenStrike: (_) => null,
              breakProtect: (_) => null,
              setWeather: (_) => null,
              setTerrain: (_) => null,
              setSideCondition: (effect) => effect.conditionId,
              setSlotCondition: (_) => null,
              setPseudoWeather: (_) => null,
              forceSwitch: (_) => null,
              selfSwitch: (_) => null,
            ),
        equals('spikes'),
      );
    });
  });
}

```


### packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Politique partagée de sélection des moves dérivés d'un learnset.
///
/// Cette extraction reste volontairement petite :
/// - elle ne crée pas un nouveau service ;
/// - elle ne change aucune règle métier ;
/// - elle évite simplement qu'un outil d'audit recopie silencieusement la
///   même logique et dérive ensuite du vrai runtime.
///
/// Règle conservée telle quelle :
/// - startingMoves
/// - relearnMoves
/// - levelUp <= niveau courant
/// - unicité préservant l'ordre
/// - 4 derniers moves maximum
List<String> deriveBattleCandidateMoveIdsFromLearnset({
  required RuntimePokemonLearnset learnset,
  required int level,
}) {
  final ordered = <String>[
    ...learnset.startingMoves,
    ...learnset.relearnMoves,
    ...learnset.levelUp
        .where((entry) => entry.level <= level)
        .map((entry) => entry.moveId),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final rawId in ordered) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    unique.add(normalizedId);
  }

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
}

/// Politique partagée de résolution runtime des moves candidats vers battle.
///
/// Cette helper donne à la fois :
/// - le comportement réel de filtrage des moves non bridgeables ;
/// - les hard failures sur moves absents du catalogue ;
/// - les hard failures sur refus bridge non filtrables.
///
/// Elle permet donc à un outil d'audit de mesurer le seam runtime avec la
/// même sévérité que la production, au lieu d'inventer une lecture plus
/// permissive.
List<BattleMoveData> resolveBattleMovesForSeed({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
}) {
  final candidateMoveIds = List<String>.unmodifiable(
    _normalizeUniqueMoveIdsPreserveOrder(moveIds)
        .take(4)
        .toList(growable: false),
  );

  if (candidateMoveIds.isEmpty) {
    throw RuntimeBattleSetupException(
      '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
    );
  }

  final moves = <BattleMoveData>[];
  final rejectedMoves = <_RejectedBridgeMove>[];

  for (final moveId in candidateMoveIds) {
    final move = lookupMove(moveId);
    if (move == null) {
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques ne contient pas "$moveId".',
        debugDetails: 'combatant=$combatantLabel',
      );
    }

    try {
      moves.add(
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        ),
      );
    } on RuntimeBattleSetupException catch (error) {
      final rejectedMove = _RejectedBridgeMove.fromBridgeRejection(
        move: move,
        debugDetails: error.debugDetails,
      );

      if (!rejectedMove.isFilterableDuringSeedAssembly) {
        rethrow;
      }

      rejectedMoves.add(rejectedMove);
    }
  }

  if (moves.isNotEmpty) {
    return List<BattleMoveData>.unmodifiable(moves);
  }

  // R1 garde ici un hard-fail volontaire :
  // - on ne réinjecte pas de move "par défaut" qui n'appartient pas au Pokémon ;
  // - on ne maquille pas non plus le trou avec un faux support Struggle runtime ;
  // - on préfère échouer tôt, avec un diagnostic produit/actionnable, tant que
  //   le bridge battle actuel ne sait pas projeter honnêtement aucune attaque
  //   du set candidat.
  throw RuntimeBattleSetupException(
    'Le combat ne peut pas démarrer car "$combatantLabel" n’a aucun move bridgeable restant après filtrage. '
    'Attribuez-lui au moins une attaque réellement supportée par le bridge battle actuel.',
    debugDetails: 'combatant=$combatantLabel, '
        'candidateMoveIds=${_formatDebugStringList(candidateMoveIds)}, '
        'rejectedMoveIds=${_formatDebugStringList(rejectedMoves.map((move) => move.moveId).toList(growable: false))}, '
        'rejectedMoves=[${rejectedMoves.map((move) => move.toDebugDetails()).join('; ')}], '
        'filterResult=no_bridgeable_moves_remaining_after_filtering, '
        'resolutionHint=assign_at_least_one_bridgeable_move',
  );
}

List<String> _normalizeUniqueMoveIdsPreserveOrder(List<String> rawIds) {
  final out = <String>[];
  final seen = <String>{};
  for (final rawId in rawIds) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    out.add(normalizedId);
  }
  return List<String>.unmodifiable(out);
}

String _formatDebugStringList(List<String> values) {
  if (values.isEmpty) {
    return '[]';
  }
  return '[${values.join(', ')}]';
}

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: combatantLabel,
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );
    final stats = _calculateStatsSnapshot(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      stats: stats,
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: request.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: teamMember.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    return deriveBattleCandidateMoveIdsFromLearnset(
      learnset: learnset,
      level: level,
    );
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    // Le builder garde désormais sa vraie policy de résolution dans une helper
    // partagée, afin que l'outillage Phase B puisse mesurer le même seam sans
    // reconstruire une variante plus permissive.
    return resolveBattleMovesForSeed(
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      lookupMove: movesCatalog.lookup,
      battleMoveBridge: battleMoveBridge,
    );
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  BattleStatsSnapshot _calculateStatsSnapshot({
    required RuntimePokemonSpecies species,
    required int level,
    PokemonStatSpread ivs = const PokemonStatSpread(),
    PokemonStatSpread evs = const PokemonStatSpread(),
  }) {
    // BE2 résout ici les stats battle non-HP pour une raison simple :
    // - `map_runtime` possède encore la donnée projet (species, niveau, IV/EV) ;
    // - `map_battle` ne doit jamais relire le JSON projet brut ;
    // - le handoff battle doit donc déjà recevoir un snapshot typé, prêt à
    //   l'emploi, au lieu d'un bricolage `power + stages`.
    //
    // Politique volontairement bornée :
    // - joueur : on utilise les IV/EV réellement présents dans la sauvegarde ;
    // - sauvage / trainer : IV/EV par défaut à 0, déterministes, documentés ;
    // - nature neutre pour tout le monde dans BE2 ;
    // - `speed` est déjà transportée pour préparer la suite, sans être
    //   consommée pour l'ordre d'action dans ce lot.
    return BattleStatsSnapshot(
      attack: _calculateResolvedNonHpStat(
        baseStat: species.baseAttack,
        level: level,
        iv: ivs.attack,
        ev: evs.attack,
      ),
      defense: _calculateResolvedNonHpStat(
        baseStat: species.baseDefense,
        level: level,
        iv: ivs.defense,
        ev: evs.defense,
      ),
      specialAttack: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialAttack,
        level: level,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
      ),
      specialDefense: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialDefense,
        level: level,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
      ),
      speed: _calculateResolvedNonHpStat(
        baseStat: species.baseSpeed,
        level: level,
        iv: ivs.speed,
        ev: evs.speed,
      ),
    );
  }

  BattleTypingSnapshot _buildBattleTypingSnapshot(
    RuntimePokemonSpecies species,
  ) {
    // BE5 garde la frontière propre :
    // - le loader species lit et valide le typing projet ;
    // - le builder l'adapte vers le petit contrat battle ;
    // - `map_battle` reçoit ensuite une donnée déjà prête à consommer sans
    //   jamais relire le JSON projet brut.
    return BattleTypingSnapshot(
      primaryType: species.typing.first,
      secondaryType: species.typing.length > 1 ? species.typing[1] : null,
    );
  }

  int _calculateResolvedNonHpStat({
    required int baseStat,
    required int level,
    int iv = 0,
    int ev = 0,
  }) {
    final safeBaseStat = _clampInt(baseStat, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(iv, min: 0, max: 31);
    final safeEv = _clampInt(ev, min: 0, max: 252);

    // Formule volontairement Pokémon-like, mais limitée et déterministe :
    // floor(((2 * base + iv + floor(ev / 4)) * level) / 100) + 5
    //
    // BE2 ne gère pas encore les natures. On garde donc ici un multiplicateur
    // neutre implicite de 1.0 au lieu d'introduire une mécanique partielle.
    final resolved =
        (((2 * safeBaseStat + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) + 5;
    return _clampInt(resolved, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Snapshot local d'un move candidat rejeté par le bridge runtime -> battle.
///
/// Ce type reste volontairement petit et local au builder :
/// - il évite d'ouvrir un nouveau contrat public juste pour un message
///   d'erreur de handoff ;
/// - il garde tout le contexte nécessaire pour expliquer pourquoi aucun move
///   bridgeable n'est finalement resté après filtrage ;
/// - il permet d'améliorer le message final sans élargir le bridge lui-même.
final class _RejectedBridgeMove {
  const _RejectedBridgeMove({
    required this.moveId,
    required this.moveName,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    this.bridgeLimit,
  });

  factory _RejectedBridgeMove.fromBridgeRejection({
    required PokemonMove move,
    required String? debugDetails,
  }) {
    return _RejectedBridgeMove(
      moveId: move.id,
      moveName: move.name,
      engineSupportLevel: move.engineSupportLevel.name,
      unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
      bridgeLimit: _extractBridgeLimit(debugDetails),
    );
  }

  final String moveId;
  final String moveName;
  final String engineSupportLevel;
  final List<String> unsupportedReasons;
  final String? bridgeLimit;

  bool get isFilterableDuringSeedAssembly {
    final limit = bridgeLimit;
    if (limit == null) {
      return false;
    }
    if (limit.startsWith('invalid_')) {
      return false;
    }
    if (limit == 'empty_modify_stats_not_supported') {
      return false;
    }
    return true;
  }

  String toDebugDetails() {
    final reasons = unsupportedReasons.isEmpty
        ? '[]'
        : '[${unsupportedReasons.join(', ')}]';
    final limit = bridgeLimit == null ? '' : ', bridgeLimit=$bridgeLimit';
    return 'moveId=$moveId, '
        'moveName=$moveName, '
        'engineSupportLevel=$engineSupportLevel, '
        'unsupportedReasons=$reasons$limit';
  }

  static String? _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.trim().isEmpty) {
      return null;
    }
    final match =
        RegExp(r'bridgeLimit=([^,]+)$').firstMatch(debugDetails.trim());
    return match?.group(1);
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    required this.typing,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData({
    int lineupIndex = 0,
  }) {
    // BE10 garde la frontière propre :
    // - le seed builder ne connaît toujours pas la vraie party runtime ;
    // - mais le mapper peut maintenant lui demander de projeter ce seed vers
    //   un `BattleCombatantData` portant une identité de lineup stable ;
    // - cela évite de dupliquer à la main tout le DTO battle dans le mapper.
    return BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

```


### packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleCombatantSeedBuilder', () {
    late Directory tempProjectRoot;
    const builder = RuntimeBattleCombatantSeedBuilder();
    const moveCatalogLoader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_combatant_seed_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('builds a player combatant seed from explicit knownMoveIds', () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(
            hp: 31,
            attack: 31,
            specialAttack: 15,
            speed: 7,
          ),
          evs: PokemonStatSpread(
            hp: 8,
            attack: 12,
            specialAttack: 20,
            speed: 16,
          ),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(seed.speciesId, equals('sproutle'));
      expect(seed.level, equals(12));
      expect(seed.maxHp, equals(36));
      expect(seed.currentHp, equals(23));
      expect(seed.abilityId, equals('overgrow'));
      expect(seed.typing.primaryType, equals('grass'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.stats.attack, equals(20));
      expect(seed.stats.defense, equals(16));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(20));
      expect(seed.stats.speed, equals(17));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stages,
        equals(-1),
      );
      expect(seed.moves[1].power, equals(45));
    });

    test(
        'toBattleCombatantData can stamp a stable lineupIndex for BE10 write-back',
        () {
      const seed = RuntimeBattleCombatantSeed(
        speciesId: 'sproutle',
        level: 12,
        maxHp: 36,
        stats: BattleStatsSnapshot(
          attack: 20,
          defense: 16,
          specialAttack: 23,
          specialDefense: 20,
          speed: 17,
        ),
        typing: BattleTypingSnapshot(primaryType: 'grass'),
        abilityId: 'overgrow',
        currentHp: 23,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'growl', name: 'Growl', power: 0),
        ],
      );

      final battleData = seed.toBattleCombatantData(lineupIndex: 2);

      expect(battleData.lineupIndex, equals(2));
      expect(battleData.speciesId, equals('sproutle'));
      expect(battleData.currentHp, equals(23));
    });

    test('preserves the BE8 move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>[
            'protect',
            'hyper_beam',
            'solar_beam',
            'feint',
          ],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['protect', 'hyper_beam', 'solar_beam', 'feint']),
      );
      expect(
        seed.moves[0].selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(seed.moves[1].requiresRecharge, isTrue);
      expect(
        seed.moves[2].chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(seed.moves[3].breaksProtect, isTrue);
    });

    test(
        'preserves the BE9 field move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['rain_dance', 'sandstorm', 'trick_room'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['rain_dance', 'sandstorm', 'trick_room']),
      );
      expect(seed.moves[0].target, equals(BattleMoveTarget.field));
      expect(seed.moves[0].weatherEffect, equals(BattleWeatherId.rain));
      expect(seed.moves[1].target, equals(BattleMoveTarget.field));
      expect(seed.moves[1].weatherEffect, equals(BattleWeatherId.sandstorm));
      expect(seed.moves[2].target, equals(BattleMoveTarget.field));
      expect(
        seed.moves[2].pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(seed.moves[2].priority, equals(-7));
    });

    test(
        'derives player moves from the learnset, falls back to species id and keeps the last four unique moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'calm',
          abilityId: 'overgrow',
          level: 25,
          currentHp: 30,
        ),
      );

      // Le seam M7 doit conserver exactement la policy historique :
      // - concat starting/relearn/levelUp<=niveau ;
      // - unicité dans l'ordre d'apparition ;
      // - puis conservation des quatre derniers si la liste déborde.
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip', 'leer', 'razor_leaf']),
      );
    });

    test('builds a wild combatant seed from species and learnset data',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildWildCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(seed.speciesId, equals('sparkitten'));
      expect(seed.level, equals(10));
      expect(seed.currentHp, isNull);
      expect(seed.abilityId, equals('blaze'));
      expect(seed.typing.primaryType, equals('fire'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.maxHp, equals(27));
      expect(seed.stats.attack, equals(15));
      expect(seed.stats.defense, equals(13));
      expect(seed.stats.specialAttack, equals(17));
      expect(seed.stats.specialDefense, equals(15));
      expect(seed.stats.speed, equals(18));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
    });

    test('builds a trainer combatant seed from explicit trainer moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildTrainerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        teamMember: const ProjectTrainerPokemonEntry(
          speciesId: 'aquafi',
          level: 18,
          moves: <String>['water_gun', 'tail_whip'],
          heldItemId: 'mystic_water',
        ),
        trainerName: 'Ace Jules',
      );

      expect(seed.speciesId, equals('aquafi'));
      expect(seed.level, equals(18));
      expect(seed.abilityId, equals('torrent'));
      expect(seed.typing.primaryType, equals('water'));
      expect(seed.typing.secondaryType, equals('fairy'));
      expect(seed.stats.attack, equals(22));
      expect(seed.stats.defense, equals(28));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(28));
      expect(seed.stats.speed, equals(20));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'filters an explicit known move that is not bridgeable when another known move remains usable',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['teleport', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['vine_whip']),
      );
    });

    test(
        'fails explicitly when explicit known moves leave no bridgeable move after filtering',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['teleport'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('candidateMoveIds=[teleport]'),
                  contains('rejectedMoveIds=[teleport]'),
                  contains('moveId=teleport'),
                  contains('moveName=Teleport'),
                  contains('engineSupportLevel=structuredPartial'),
                  allOf(
                    contains(
                      'unsupportedReasons=[unsupported_mechanic:zMove]',
                    ),
                    contains(
                      'filterResult=no_bridgeable_moves_remaining_after_filtering',
                    ),
                    contains(
                      'resolutionHint=assign_at_least_one_bridgeable_move',
                    ),
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'does not silently filter malformed move data just because another move is bridgeable',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      const builderWithRejectingBridge = RuntimeBattleCombatantSeedBuilder(
        battleMoveBridge: _RejectingRuntimeBattleMoveBridge(
          rejectedMoveId: 'thunder_wave',
          rejection: RuntimeBattleSetupException(
            'Le combat ne peut pas démarrer car "Le Pokémon actif du joueur" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
            debugDetails:
                'combatant=Le Pokémon actif du joueur, moveId=thunder_wave, moveName=Thunder Wave, bridgeLimit=invalid_apply_status_scope:self',
          ),
        ),
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builderWithRejectingBridge.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['thunder_wave', 'vine_whip'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=invalid_apply_status_scope:self'),
          ),
        ),
      );
    });

    test('fails explicitly when a requested move is absent from the catalog',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['move_that_does_not_exist'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'fails explicitly when a learnset-derived move list has no bridgeable moves left after filtering',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'vine_whip',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('candidateMoveIds=[tackle, growl, vine_whip]'),
                  contains('rejectedMoveIds=[tackle, growl, vine_whip]'),
                  contains('moveId=tackle'),
                  contains('moveId=growl'),
                  contains('moveId=vine_whip'),
                  contains(
                    'filterResult=no_bridgeable_moves_remaining_after_filtering',
                  ),
                  contains(
                    'resolutionHint=assign_at_least_one_bridgeable_move',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'keeps a structured supported major status move once BE7 opens applyStatus honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['thunder_wave'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('thunder_wave'));
      expect(
        seed.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test(
        'keeps a non-zero priority move once battle order consumes it honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['quick_attack'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('quick_attack'));
      expect(seed.moves.single.priority, equals(1));
    });

    test('keeps a non-trivial accuracy move once battle owns the hit check',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['mud_slap'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('mud_slap'));
      expect(seed.moves.single.accuracy.kind,
          equals(BattleMoveAccuracyKind.percent));
      expect(seed.moves.single.accuracy.value, equals(85));
    });

    test(
        'keeps a non-neutral crit ratio once battle owns minimal critical hits',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['razor_leaf'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('razor_leaf'));
      expect(seed.moves.single.critRatio, equals(2));
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{'learnset': 'sproutle'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'refs': <String, String>{'learnset': 'sparkitten'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'refs': <String, String>{'learnset': 'aquafi'},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle', 'growl'],
      'relearnMoves': <String>['growl', 'vine_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'vine_whip', 'level': 7},
        <String, Object>{'moveId': 'leer', 'level': 13},
        <String, Object>{'moveId': 'razor_leaf', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'ember', 'level': 7},
        <String, Object>{'moveId': 'flame_wheel', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'tail_whip', 'level': 18},
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime combatant seed builder test catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry(
          'teleport',
          'Teleport',
          0,
          target: PokemonMoveTarget.self,
          pp: 20,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>['unsupported_mechanic:zMove'],
        ),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('leer', 'Leer', 0),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('quick_attack', 'Quick Attack', 40, priority: 1),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures runtime doivent rester canoniques :
  // - `growl` / `tail_whip` / `leer` portent de vrais effets structurés ;
  // - `thunder_wave` sert maintenant de move de statut majeur réellement
  //   supporté par le petit sous-ensemble BE7 ;
  // - `rain_dance` / `sandstorm` / `trick_room` servent à prouver que le
  //   builder ne reperd pas les nouveaux champs BE9 pendant la projection ;
  // - les autres moves restent de simples attaques standard pour garder les
  //   happy paths lisibles.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' || 'leer' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason:
        'Expected to find move "$moveId" in the combatant seed builder fixture catalog.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': primaryAbilityId},
      // Le test retire volontairement `refs.learnset` pour prouver que le
      // seam M7 conserve bien le fallback historique vers l'id d'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

final class _RejectingRuntimeBattleMoveBridge extends RuntimeBattleMoveBridge {
  const _RejectingRuntimeBattleMoveBridge({
    required this.rejectedMoveId,
    required this.rejection,
  });

  final String rejectedMoveId;
  final RuntimeBattleSetupException rejection;

  @override
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // Ce faux bridge cible exactement la policy du builder :
    // - le catalogue reste canonique et chargeable ;
    // - l'échec est injecté au seam runtime -> battle réellement concerné ;
    // - le test prouve donc que le builder ne masque pas un rejet
    //   explicitement non filtrable sous prétexte qu'un autre move passerait.
    if (move.id == rejectedMoveId) {
      throw rejection;
    }
    return super.toBattleMoveData(
      move: move,
      combatantLabel: combatantLabel,
    );
  }
}

```


### packages/map_runtime/test/runtime_battle_setup_mapper_test.dart

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.playerPokemon.typing!.primaryType, equals('grass'));
      expect(setup.playerPokemon.typing!.secondaryType, isNull);
      expect(setup.playerPokemon.stats.attack, equals(16));
      expect(setup.playerPokemon.stats.specialAttack, equals(20));
      expect(setup.playerPokemon.stats.speed, equals(15));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'tail_whip'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'maps player reserves from the real party and excludes bench members already KO',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 23,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 17,
              ),
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'rash',
                abilityId: 'blaze',
                level: 16,
                knownMoveIds: <String>['ember'],
                currentHp: 0,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerReservePokemon, hasLength(1));
      expect(setup.playerReservePokemon.single.speciesId, equals('aquafi'));
      expect(setup.playerReservePokemon.single.lineupIndex, equals(1));
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('fire'));
      expect(setup.enemyPokemon.typing!.secondaryType, isNull);
      expect(setup.enemyPokemon.stats.attack, equals(15));
      expect(setup.enemyPokemon.stats.specialAttack, equals(17));
      expect(setup.enemyPokemon.stats.speed, equals(18));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .targetStatStageChanges
            .single
            .stat,
        equals(BattleStatId.defense),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test(
        'preserves typing through to battle so STAB and effectiveness are really consumed',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-type-bridge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 12,
                knownMoveIds: <String>['ember'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sproutle',
          level: 10,
        ),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(execution.move.id, equals('ember'));
      expect(execution.didHit, isTrue);
      expect(execution.stabMultiplier, equals(1.5));
      expect(execution.typeEffectivenessMultiplier, equals(2.0));
      expect(execution.damage, greaterThan(0));
    });

    test(
        'maps a non-trivial accuracy move honestly through to battle, where it can miss deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-accuracy',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['mud_slap'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(
        setup.playerPokemon.moves.single.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(setup.playerPokemon.moves.single.accuracy.value, equals(85));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 100]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('mud_slap'));
      expect(execution.didHit, isFalse);
      expect(session.state.enemy.currentHp, equals(setup.enemyPokemon.maxHp));
    });

    test(
        'maps a non-neutral crit ratio honestly through to battle, where it can crit deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-crits',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['razor_leaf'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(setup.playerPokemon.moves.single.id, equals('razor_leaf'));
      expect(setup.playerPokemon.moves.single.critRatio, equals(2));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 1]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('razor_leaf'));
      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });

    test('falls back to the species id when the species has no learnset ref',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-species-id-fallback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'tail_whip'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('water'));
      expect(setup.enemyPokemon.typing!.secondaryType, equals('fairy'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
      expect(setup.enemyReservePokemon, isEmpty);
    });

    test('maps trainer reserves instead of stopping at trainer.team.first',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyReservePokemon, hasLength(1));
      expect(setup.enemyReservePokemon.single.speciesId, equals('sparkitten'));
      expect(setup.enemyReservePokemon.single.lineupIndex, equals(1));
    });

    test(
        'maps a trainer with explicit mixed moves by keeping only the bridgeable subset',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['teleport', 'water_gun'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun']),
      );
    });

    test(
        'mapped trainer multi-mon battle auto-replaces the enemy instead of ending on the first KO',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['growl'],
              ),
              ProjectTrainerPokemonEntry(
                speciesId: 'sparkitten',
                level: 17,
                moves: <String>['ember'],
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trainer-reserve',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 40,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 99,
              ),
            ],
          ),
        ),
        request: _trainerRequest(),
      );

      final afterTurn = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('sparkitten'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .where((event) => event.actor == 'enemy'),
        hasLength(1),
      );
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'keeps a battle setup honest when explicit known moves mix unsupported and supported entries',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-known-move-filtering',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['teleport', 'vine_whip'],
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves
            .map((move) => move.id)
            .toList(growable: false),
        equals(<String>['vine_whip']),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(execution.move.id, equals('vine_whip'));
    });

    test(
        'fails explicitly when explicit known moves leave no bridgeable move after filtering',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-no-bridgeable-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['teleport'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('candidateMoveIds=[teleport]'),
                  contains('rejectedMoveIds=[teleport]'),
                  contains('moveId=teleport'),
                  contains('moveName=Teleport'),
                  contains('unsupportedReasons=[unsupported_mechanic:zMove]'),
                  contains(
                    'resolutionHint=assign_at_least_one_bridgeable_move',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'filters learnset-derived moves and keeps the bridgeable subset when at least one move remains',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-derived-filtered-move',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves
            .map((move) => move.id)
            .toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
    });

    test(
        'fails explicitly when a learnset-derived move list has no bridgeable move after filtering',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'vine_whip',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-no-bridgeable-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('aucun move bridgeable restant après filtrage'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('candidateMoveIds=[tackle, growl, vine_whip]'),
                  contains('rejectedMoveIds=[tackle, growl, vine_whip]'),
                  contains('moveId=tackle'),
                  contains('moveId=growl'),
                  contains('moveId=vine_whip'),
                  contains(
                    'resolutionHint=assign_at_least_one_bridgeable_move',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'maps a supported major status move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-major-status',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['thunder_wave'],
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves.single.id, equals('thunder_wave'));
      expect(
        setup.playerPokemon.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );

      final session = createBattleSession(setup);
      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.majorStatus?.id,
          equals(BattleMajorStatusId.par));
      expect(
        afterTurn.state.currentTurn?.statusEvents
            .where((event) => event.kind == BattleStatusEventKind.applied)
            .single
            .sourceMoveId,
        equals('thunder_wave'),
      );
    });

    test(
        'maps a supported requireRecharge move and keeps the forced follow-up honest in battle',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-recharge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 80,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 120,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'aquafi',
          level: 80,
        ),
      );

      expect(setup.playerPokemon.moves.single.requiresRecharge, isTrue);

      final afterAttack = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[1, 24, 24, 24]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(afterAttack.getAvailableChoices().single,
          isA<PlayerBattleChoiceContinue>());

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn?.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
    });

    test('maps a supported weather move and lets battle consume rain honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final rainySetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-dance',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['rain_dance', 'water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        rainySetup.playerPokemon.moves.first.weatherEffect,
        equals(BattleWeatherId.rain),
      );

      final rainySession = createBattleSession(rainySetup);
      final afterRain =
          rainySession.applyChoice(const PlayerBattleChoiceFight(0));
      final rainyAttack =
          afterRain.applyChoice(const PlayerBattleChoiceFight(1));
      final rainyDamage = rainyAttack.state.currentTurn!.executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      final neutralSetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-neutral',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      final neutralDamage = createBattleSession(neutralSetup)
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      expect(afterRain.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterRain.state.currentTurn!.fieldEvents
            .where((event) => event.kind == BattleFieldEventKind.weatherSet)
            .single
            .weather,
        equals(BattleWeatherId.rain),
      );
      expect(rainyDamage, greaterThan(neutralDamage));
    });

    test('maps a supported Trick Room move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trick-room',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['trick_room', 'tackle'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.first.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(setup.playerPokemon.moves.first.priority, equals(-7));

      final session = createBattleSession(setup);
      final afterRoom = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterAttack =
          afterRoom.applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        afterRoom.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterAttack.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'tail_whip',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry(
          'teleport',
          'Teleport',
          0,
          target: PokemonMoveTarget.self,
          pp: 20,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>['unsupported_mechanic:zMove'],
        ),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures de mapper restent volontairement petites et canoniques :
  // - on encode seulement les effets déjà réellement consommés par le moteur ;
  // - BE9 ajoute ici juste assez de champ pour pluie / tempête de sable /
  //   Trick Room ;
  // - on ne crée pas un faux mini-catalogue parallèle plus riche que le repo.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{
        'primary': primaryAbilityId,
      },
      // Ce helper retire volontairement `refs.learnset` pour vérifier que le
      // mapper, via le loader learnset, retombe bien sur l'id de l'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

```
