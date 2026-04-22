# Lot 9-e — Battle BAG potion turn commit

## Résumé exécutif

Le lot 9-e est implémenté comme une vraie action de tour committée pour `Potion`, sans ouvrir de système générique d'objets battle.

Le changement clé est un micro-seam explicite côté `map_battle` : `Potion` ne passe plus par un patch runtime local pendant l'état de décision, mais par une vraie action de tour schedulée, résolue, tracée dans la timeline, puis reflétée côté runtime par la consommation réelle du bag et le write-back réel de la lineup joueur.

Résultat produit :
- sélectionner `Potion` + une cible valide consomme bien le tour du joueur ;
- le joueur ne peut plus choisir ensuite une attaque dans ce même tour ;
- l'adversaire répond dans le flow normal du tour ;
- la timeline / présentation raconte honnêtement l'usage de `Potion` ;
- le soin réel `+20`, capé à `maxHp`, et la consommation réelle du bag restent en place ;
- aucun système générique d'items battle n'a été introduit.

## Confirmation de scope

Ce lot continue bien le fil BAG runtime/UI/runtime/battle :
- lot-9a : battle BAG menu UI shell
- lot-9b : capture wiring
- lot-9c : medicine target shell
- lot-9d : Potion real apply
- lot-9e : Potion committed turn

Ce lot ne continue pas BDC-01.

Ce lot ne modifie pas :
- le bridge runtime -> battle des moves ;
- `Bubble` / `Bubble Beam` ;
- le converter Showdown ;
- la capture lot 9-b ;
- un quelconque framework générique d'items battle.

## Audit du prompt et remise en cause argumentée

### Point remis en cause

Le prompt autorisait soit :
- un seam runtime qui commit le tour sans nouveau choix battle générique ;
- soit un micro-seam `map_battle` si nécessaire.

### Pourquoi le prompt ne pouvait pas être suivi aveuglément en runtime-only

Le repo prouvait que le lot 9-d n'était pas un vrai commit de tour :
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart>) appliquait encore un patch local sur la session et le `GameState` ;
- aucun vrai `currentTurn` battle n'était créé ;
- la timeline n'était pas produite par le moteur pour l'usage de `Potion` ;
- l'adversaire ne répondait pas via le même scheduler de tour que les actions battle déjà honnêtes ;
- le joueur pouvait donc être soigné sans que cela existe comme action de tour pleinement assumée par `map_battle`.

En clair, une lecture trop littérale de type "runtime only" aurait prolongé le mensonge structurel de 9-d au lieu de le corriger.

### Preuves trouvées dans le repo

Audit initial des seams existants :
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart>) : patch local runtime sur session + bag.
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart>) : seul `applyChoice(...)` créait un vrai tour résolu avec `currentTurn`.
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart>) : le scheduler existant était déjà la vraie source de vérité pour le flow du tour, mais ne connaissait pas `Potion`.
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart>) : l'overlay pouvait déjà raconter un tour battle, mais pas un vrai objet committé par le moteur.

### Alternative retenue

J'ai retenu l'option la plus petite et honnête :
- **un micro-seam battle spécifique à `Potion`** ;
- aucune action item générique ;
- aucune lecture du bag côté moteur ;
- aucune taxonomie extensible de 20 objets ;
- runtime toujours propriétaire du bag réel et du write-back party.

### Interprétation finale adoptée

J'ai donc changé l'interprétation du prompt ainsi :
- refus d'une solution runtime-only qui continuerait à contourner le vrai flow de tour ;
- acceptation d'un seam battle minimal et ultra-borné à `Potion` seulement ;
- maintien de toute la logique de disponibilité / consommation du bag côté runtime.

## Audit initial

### Rapports relus

- [`/Users/karim/Project/pokemonProject/reports/lot-9a-battle-bag-menu-ui-shell-report.md`](</Users/karim/Project/pokemonProject/reports/lot-9a-battle-bag-menu-ui-shell-report.md>)
- [`/Users/karim/Project/pokemonProject/reports/lot-9b-battle-bag-capture-wiring-report.md`](</Users/karim/Project/pokemonProject/reports/lot-9b-battle-bag-capture-wiring-report.md>)
- [`/Users/karim/Project/pokemonProject/reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`](</Users/karim/Project/pokemonProject/reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md>)
- [`/Users/karim/Project/pokemonProject/reports/lot-9c-battle-bag-medicine-target-shell-report.md`](</Users/karim/Project/pokemonProject/reports/lot-9c-battle-bag-medicine-target-shell-report.md>)
- [`/Users/karim/Project/pokemonProject/reports/lot-9d-battle-bag-potion-real-apply-report.md`](</Users/karim/Project/pokemonProject/reports/lot-9d-battle-bag-potion-real-apply-report.md>)
- [`/Users/karim/Project/pokemonProject/reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`](</Users/karim/Project/pokemonProject/reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md>)

### Fichiers audités en priorité

Runtime / overlay :
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart>)

Battle :
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart>)

Tests audités :
- [`/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`](</Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart>)
- [`/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`](</Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart>)

### Contrats identifiés avant implémentation

- `PlayableMapGame` reste le propriétaire runtime de vérité pour `_battleSession` et `_gameState`.
- `BattleSession.applyChoice(...)` et son scheduler sont le vrai seam de commit d'un tour battle.
- `lineupIndex` est déjà l'identité stable correcte pour cibler un membre du lineup battle.
- La capture lot 9-b est déjà un flow spécifique et ne doit pas être mélangée à `Potion`.
- Le helper de write-back lineup complet existe déjà côté runtime et devait être réutilisé, sinon 9-e aurait menti sur l'état final du joueur après la réponse adverse.

### Risques principaux identifiés avant implémentation

- continuer 9-d en runtime-only et mentir encore sur le commit de tour ;
- ouvrir un faux système générique d'items ;
- consommer le bag sans vrai tour battle ;
- produire une timeline overlay-only sans support moteur ;
- introduire une divergence entre session battle, `GameState`, overlay et host runtime.

### Limites de scope à préserver

- `Potion` seulement ;
- aucun `PlayerBattleChoiceUseItem` ;
- aucun registre d'items ;
- aucune médecine supplémentaire ;
- capture inchangée ;
- bridge de moves inchangé.

## État git initial

État observé au tout début du lot 9-e :

`git status --short --untracked-files=all`
```text
<aucune sortie>
```

`git diff --stat`
```text
<aucune sortie>
```

Le worktree était propre au démarrage du lot.

## Décision d'architecture retenue

### Réponse explicite à la question d'architecture

**Quel est le plus petit seam honnête pour faire de `Potion` une vraie action de tour ?**

Réponse : **Option A bornée**.

Plus précisément :
- un choix / une action battle très étroit(e), spécifique à `Potion` ;
- aucun contrat d'items battle générique ;
- le runtime conserve le bag réel et sa consommation ;
- le moteur battle prend uniquement la responsabilité minimale qui lui manquait : committer, scheduler et raconter honnêtement un tour `Potion`.

### Pourquoi cette option est la plus petite et la plus sûre

- Elle réutilise le scheduler battle existant au lieu de le contourner.
- Elle garde la consommation du bag hors moteur, donc pas de couplage bag <-> battle.
- Elle n'ouvre aucune surface générique type `BattleItemActionRegistry`.
- Elle rend `Potion` testable comme vraie action de tour sans vendre un support plus large que le repo n'a pas.

### Pourquoi les autres options ont été refusées

- **Runtime-only commit** : trop mensonger, car pas de vrai `currentTurn`, pas de vraie timeline moteur, pas de vraie sémantique de tour committé.
- **Framework d'items battle** : trop large pour 9-e, contraire au prompt et à l'architecture existante.

## Sémantique exacte du flow 9-e

### Ce qui se passe maintenant

1. Le joueur choisit `Potion` puis une cible valide dans le shell 9-c.
2. Le runtime valide encore le bag réel et le `lineupIndex` cible.
3. `BattleSession.applyPotionTurn(...)` commit un vrai tour battle.
4. Le scheduler battle résout `BattleActionPotionUse` comme action du joueur.
5. Le moteur enregistre un `BattleTurnPotionEvent` dans le `currentTurn` et la timeline.
6. L'action adverse se résout ensuite dans le flow normal du tour.
7. Le runtime consomme une `Potion` dans `GameState.bag`.
8. Le runtime réécrit la lineup joueur engagée dans la party save via le helper de write-back.
9. L'overlay rejoue honnêtement la présentation du tour à partir du `currentTurn` réel.
10. Le joueur ne récupère un nouvel état de décision que pour le tour suivant.

### Timing précis documenté

- **moment du commit** : dans `BattleSession.applyPotionTurn(...)`.
- **moment du heal battle** : dans le scheduler, au moment où `BattleActionPotionUse` est exécutée.
- **moment de production timeline** : au même moment, via `BattleTurnPotionEvent` + `BattlePotionEvent` dans `BattleTurnResult`.
- **moment de la réponse adverse** : plus loin dans le même flow de tour du scheduler.
- **moment de la consommation du bag** : côté runtime, après retour d'un commit battle réussi, dans `tryApplyRuntimeBattlePotionUse(...)`.
- **moment du write-back de la party** : dans ce même helper runtime, après résolution du tour, à partir de la `BattleSession` mise à jour.

## Sub-agents / passes locales et verdicts

L'environnement refusait l'ouverture de nouveaux sub-agents réels (`agent thread limit reached (max 6)`), donc j'ai exécuté des passes locales explicitement nommées comme sub-agents.

- **Sub-agent Audit / Architecture** : **OK**
  - a confirmé que 9-d n'était pas un vrai turn commit ;
  - a refusé la solution runtime-only ;
  - a retenu le micro-seam battle spécifique à `Potion`.

- **Sub-agent Implémentation** : **OK**
  - a introduit une action battle `Potion` bornée ;
  - a repositionné 9-d dans un vrai commit de tour ;
  - a gardé bag et write-back côté runtime.

- **Sub-agent Tests** : **OK**
  - a ajouté la couverture battle, runtime, présentation et intégration ;
  - a ajusté les assertions trop faibles ou trop mensongères.

- **Sub-agent Build / Validation** : **OK**
  - `map_battle` complet vert ;
  - `map_runtime` complet vert ;
  - analyse ciblée battle et runtime verte ;
  - host smoke test downstream vert.

- **Sub-agent Critique finale** : **OK**
  - a validé que le seam reste strictement borné à `Potion` ;
  - a identifié des risques résiduels réels documentés plus bas ;
  - a confirmé l'absence de framework générique d'items.

## Fichiers modifiés et impact attendu

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
- Zones modifiées : ajout de `BattleActionPotionUse`.
- Raison : créer une vraie action de tour minimale pour `Potion`.
- Impact attendu : `Potion` devient une action schedulable du moteur, sans ouvrir d'API d'items génériques.

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`
- Zones modifiées : whitelist des actions gérées par la queue.
- Raison : permettre au scheduler d'accepter `Potion` comme vraie action de tour.
- Impact attendu : `Potion` est traitée dans la même mécanique de queue que les actions honnêtes déjà existantes.

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
- Zones modifiées : ajout de `potionEvents`, `BattlePotionEvent`, `BattleTurnPotionEvent`.
- Raison : rendre l'usage de `Potion` visible et testable dans le `BattleTurnResult`.
- Impact attendu : la timeline et la présentation peuvent raconter honnêtement l'usage de `Potion`.

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- Zones modifiées : ajout de `applyPotionTurn(...)`, mutualisation via `_applyCommittedPlayerAction(...)`, helpers de résolution / validation de cible.
- Raison : committer un vrai tour `Potion` sans contourner le scheduler.
- Impact attendu : `Potion` engage réellement le tour du joueur et produit un `currentTurn` battle normal.

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- Zones modifiées : exécution de `BattleActionPotionUse`, priorité locale bornée, propagation des `potionEvents`.
- Raison : intégrer `Potion` dans le flow réel de résolution du tour.
- Impact attendu : `Potion` résout dans le tour, puis l'adversaire répond normalement.

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`
- Zones modifiées : nouveaux tests de commit de tour `Potion` et garde-fous de cible invalide.
- Raison : prouver que `Potion` est désormais une vraie action de tour battle.
- Impact attendu : empêcher une régression vers un simple patch runtime local.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- Zones modifiées : exposition publique du helper de write-back lineup complet.
- Raison : après une réponse adverse dans le même tour, il faut réécrire honnêtement toute la lineup engagée, pas seulement la cible soignée.
- Impact attendu : pas de divergence entre `BattleSession` finale et `GameState.party`.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
- Zones modifiées : helper 9-d repositionné pour appeler le vrai commit battle puis consommer le bag + write-back.
- Raison : absorber 9-d dans 9-e sans garder de faux apply local.
- Impact attendu : l'effet runtime reste réel, mais uniquement après un vrai commit de tour.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- Zones modifiées : callback `onPotionUseRequested`, narration overlay, durée / animation de présentation, application des steps visuels.
- Raison : arrêter de patcher la session localement et raconter le vrai `currentTurn` battle.
- Impact attendu : l'overlay n'autorise plus un faux état de décision libre après `Potion` et affiche un vrai flow de résolution.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`
- Zones modifiées : support des `BattleTurnPotionEvent` et animation de heal honnête.
- Raison : faire de `Potion` un événement présenté comme un vrai tour.
- Impact attendu : le joueur voit `Potion` utilisée puis les PV remonter avant la réponse adverse.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- Zones modifiées : `_onBattlePotionUseRequested(...)`.
- Raison : `PlayableMapGame` reste propriétaire de `_battleSession` et `_gameState`, et doit recevoir le résultat du vrai commit de tour.
- Impact attendu : pas de divergence entre overlay, session et runtime parent.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- Zones modifiées : tests overlay `Potion` maintenant orientés vrai commit de tour.
- Raison : prouver que l'overlay ne dispatch pas de faux `PlayerBattleChoice` et entre bien en présentation réelle.
- Impact attendu : verrou sur le comportement UX 9-e.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
- Zones modifiées : assertions sur `currentTurn`, stabilisation des attentes via un move ennemi `Wait`.
- Raison : tester le vrai helper runtime 9-e sans bruit de dégâts adverses dans certains cas unitaires.
- Impact attendu : couverture fiable de la consommation bag + write-back + commit de tour.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`
- Zones modifiées : nouveau test de narration / timeline `Potion`.
- Raison : prouver que la présentation raconte un vrai usage d'objet puis la réponse adverse.
- Impact attendu : évite un simple feedback overlay local trompeur.

### `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- Zones modifiées : assertions d'intégration sur `currentTurn`, `potionEvents`, sync session/gameState.
- Raison : verrouiller l'intégration parent runtime après usage réel de `Potion`.
- Impact attendu : couverture d'intégration aval du seam 9-e.

## Tests créés ou modifiés

Tests créés / renforcés pour ce lot :
- `BattleSession applyPotionTurn commits a real turn and the enemy still responds in the same turn flow`
- `BattleSession` garde-fous sur cible `full HP` et cible `K.O.`
- `buildBattleTurnPresentationSteps renders potion use as a committed turn step before the enemy response`
- assertions overlay sur vrai `currentTurn`, vraie narration `Potion`, absence de `PlayerBattleChoice`
- assertions runtime sur consommation réelle du bag, `currentTurn` réel, disparition d'entrée quantité `1`
- assertions d'intégration sur la cohérence `BattleSession` / `GameState` après un vrai tour `Potion`

Non-régressions explicitement conservées :
- capture 9-b ;
- forced replacement sans accès au BAG ;
- move choices inchangés ;
- switch flow inchangé.

## Commandes de test lancées et résultats exacts

### Tests ciblés `map_battle`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart
```
Résultat : **vert**.

### Suite complète `map_battle`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test
```
Résultat : **vert** (`All tests passed!`).

### Tests ciblés `map_runtime`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_turn_presentation_test.dart
```
Résultat : **vert**.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_potion_apply_runtime_test.dart
```
Résultat : **vert**.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart
```
Résultat : **vert**.

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/wild_battle_end_to_end_flow_test.dart
```
Résultat final : **vert**.

Note honnête : une première version de ce test a échoué parce qu'elle exigeait un texte overlay exact trop fort pour le seam d'intégration. J'ai corrigé le test pour prouver la vérité runtime/session (`currentTurn`, `potionEvents`, sync `GameState`) plutôt qu'un détail de prompt déjà couvert par les tests overlay dédiés.

### Suite complète `map_runtime`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test
```
Résultat : **vert** (`All tests passed!`).

### Validation downstream host

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart
```
Résultat : **vert**.

## Commandes d'analyse lancées et résultats exacts

### Analyse `map_battle`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_action.dart lib/src/battle_queue.dart lib/src/battle_resolution.dart lib/src/battle_session.dart lib/src/battle_session_scheduler.dart test/battle_session_test.dart
```
Résultat : **vert** (`No issues found!`).

### Analyse `map_runtime`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_outcome_apply.dart lib/src/application/runtime_battle_potion_apply.dart lib/src/presentation/flame/battle_overlay_component.dart lib/src/presentation/flame/battle_turn_presentation.dart lib/src/presentation/flame/playable_map_game.dart test/battle_overlay_component_test.dart test/battle_potion_apply_runtime_test.dart test/battle_turn_presentation_test.dart test/wild_battle_end_to_end_flow_test.dart
```
Résultat final : **vert** (`No issues found!`).

Note honnête : une première passe a sorti un seul lint info-level `prefer_const_constructors` dans `battle_potion_apply_runtime_test.dart`, corrigé avant relance.

## Commandes de build lancées et résultats exacts

### Build package

Aucun `flutter build` ou `dart compile` package-level n'est applicable ici comme validation principale :
- `packages/map_battle` est une bibliothèque Dart pure, pas une app buildable autonome ;
- `packages/map_runtime` est un package Flutter de bibliothèque, pas une application Flutter autonome.

### Validation alternative retenue

La validation build honnête pour ce lot est donc :
- analyse ciblée des surfaces touchées ;
- suites de tests ciblées ;
- suite complète `map_battle` ;
- suite complète `map_runtime` ;
- smoke test downstream du host runtime consommateur.

### Host buildable considéré dans l'audit

Le host buildable directement consommateur est :
- [`/Users/karim/Project/pokemonProject/examples/playable_runtime_host`](</Users/karim/Project/pokemonProject/examples/playable_runtime_host>)

Je n'ai pas lancé `flutter build` du host desktop dans ce lot parce que :
- aucun code spécifique plateforme / runner n'a été touché ;
- le seam concerné est bibliothèque runtime + battle ;
- le smoke test host ciblé est une meilleure validation rapide et stable dans cette session.

## Classification de dirtiness

### Modifiés par ce lot

- les 15 fichiers source / test listés ci-dessus ;
- ce report : `/Users/karim/Project/pokemonProject/reports/lot-9e-battle-bag-potion-turn-commit-report.md`

### Dirtiness hors scope observée en fin de lot

En fin de lot, deux arbres non suivis hors scope sont apparus dans `git status` :
- `pokemon-showdown-client-master/`
- `sprites-master/`

Ils ne sont pas nécessaires au lot 9-e, n'ont pas été modifiés par le travail ci-dessus, et sont donc classés **hors scope / non touchés** dans ce report.

## Limites explicitement conservées

- `Potion` seulement ;
- aucun système générique d'items battle ;
- aucun `PlayerBattleChoiceUseItem` ;
- aucun registre / catalogue runtime d'items ;
- aucun `Antidote`, `Super Potion`, `Revive`, `X Attack`, held items, etc. ;
- capture 9-b inchangée ;
- bridge de moves inchangé ;
- aucun changement BDC-01.

## Auto-critique finale honnête

### Risques restants

- La priorité locale donnée à `Potion` (`7`) est volontairement bornée et honnête pour 9-e, mais ce n'est pas un modèle complet des priorités d'items de toute la série. Si d'autres objets de tour arrivent un jour, cette règle devra être revisitée au lieu d'être étendue aveuglément.
- La narration / animation de heal est pleinement honnête pour la cible active. Pour une cible réserve, la vérité runtime et textuelle est correcte, mais il n'existe toujours pas de grand système d'animation riche de carte réserve ; ce n'est pas un bug de 9-e, c'est une limite assumée du scope UI actuel.
- La consommation du bag reste côté runtime après un commit battle réussi. C'est le bon choix pour 9-e, mais cela veut dire que si un futur besoin impose des objets avec règles de consommation conditionnelles complexes, il faudra repenser la frontière sans transformer ce seam `Potion` en framework caché.

### Tests manquants possibles

- Un test battle plus explicite sur l'ordre relatif `Potion` vs move de priorité très haute pourrait être ajouté si le produit veut figer cette convention locale.
- Un test host UI plus end-to-end avec vraie présentation frame par frame pourrait encore renforcer la confiance, même si la couverture runtime + host smoke est déjà solide pour ce lot.

### Choix discutables mais assumés

- Introduction d'un micro-seam battle au lieu d'un seam runtime-only. Ce choix est assumé parce qu'il est plus honnête que de prolonger 9-d, tout en restant beaucoup plus petit qu'un système générique d'items.
- Réutilisation du helper de write-back lineup complet plutôt qu'une simple mise à jour de la cible soignée. Cela augmente un peu le blast radius runtime immédiat, mais c'est la seule façon honnête de refléter la réponse adverse dans le `GameState.party` sans divergence.

### Pourquoi ce lot reste borné malgré tout

- l'action ajoutée s'appelle littéralement `BattleActionPotionUse`, pas `BattleActionUseItem` ;
- l'événement ajouté s'appelle `BattlePotionEvent`, pas `BattleItemEvent` ;
- le moteur ne lit toujours pas le bag ;
- le runtime ne charge toujours aucun catalogue item ;
- la capture et les autres médecines n'ont pas été rouvertes.

## Prochaines étapes proposées, sans implémentation

- lot 9-f : décider si `Potion` doit consommer le tour avec une présentation encore plus explicite côté host complet / UX desktop ;
- lot medicine suivant : ajouter éventuellement `Super Potion` ou `Antidote`, mais seulement si chaque objet garde un seam tout aussi honnête ;
- éventuel lot UX : enrichir l'animation / feedback visuel de heal sur une cible réserve, sans toucher au contrat battle.

## État git final
```text
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_queue.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_potion_apply_runtime_test.dart
 M packages/map_runtime/test/battle_turn_presentation_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? pokemon-showdown-client-master/
?? reports/lot-9e-battle-bag-potion-turn-commit-report.md
?? sprites-master/
```

`git diff --stat`
```text
 packages/map_battle/lib/src/battle_action.dart     |  31 ++++
 packages/map_battle/lib/src/battle_queue.dart      |   5 +-
 packages/map_battle/lib/src/battle_resolution.dart |  42 +++++
 packages/map_battle/lib/src/battle_session.dart    | 178 ++++++++++++++++++---
 .../lib/src/battle_session_scheduler.dart          |  64 ++++++--
 packages/map_battle/test/battle_session_test.dart  | 135 ++++++++++++++++
 .../application/runtime_battle_outcome_apply.dart  |  16 +-
 .../application/runtime_battle_potion_apply.dart   |  93 +++--------
 .../flame/battle_overlay_component.dart            |  58 +++----
 .../flame/battle_turn_presentation.dart            |  96 +++++++----
 .../src/presentation/flame/playable_map_game.dart  |  65 +++++---
 .../test/battle_overlay_component_test.dart        | 137 ++++++++++------
 .../test/battle_potion_apply_runtime_test.dart     |  35 ++--
 .../test/battle_turn_presentation_test.dart        | 104 ++++++++++++
 .../test/wild_battle_end_to_end_flow_test.dart     |  24 ++-
 15 files changed, 817 insertions(+), 266 deletions(-)
```

Note : ce report est lui-même un fichier touché. Son contenu complet est ce document ; il n’existe pas de self-diff récursif utile à ajouter ici.

## Diffs exhaustifs de tous les fichiers touchés


### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart

```diff
diff --git a/packages/map_battle/lib/src/battle_action.dart b/packages/map_battle/lib/src/battle_action.dart
index b381c782..a58ceeb6 100644
--- a/packages/map_battle/lib/src/battle_action.dart
+++ b/packages/map_battle/lib/src/battle_action.dart
@@ -120,6 +120,37 @@ class BattleActionRun extends BattleAction {
   const BattleActionRun();
 }
 
+/// Utiliser une Potion sur un membre du lineup joueur courant.
+///
+/// Lot 9-e ouvre ici un seam volontairement ultra-borné :
+/// - aucune taxonomie générique d'objets battle ;
+/// - aucune lecture de bag côté moteur ;
+/// - aucune famille "item use" extensible pour 20 objets ;
+/// - uniquement la forme minimale nécessaire pour faire de `Potion`
+///   une vraie action de tour committée et visible dans la timeline.
+///
+/// Le runtime reste responsable de deux vérités hors moteur :
+/// - vérifier qu'une Potion existe vraiment dans le `GameState.bag` ;
+/// - décrémenter cette entrée après un commit de tour réussi.
+class BattleActionPotionUse extends BattleAction {
+  const BattleActionPotionUse({
+    required this.targetLineupIndex,
+    required this.healAmount,
+  }) : assert(healAmount > 0, 'Potion healAmount must stay strictly positive.');
+
+  /// Lineup cible côté joueur.
+  ///
+  /// On reste sur l'identité stable battle `lineupIndex` pour éviter
+  /// tout couplage fragile à un index visuel d'overlay ou à un slot save.
+  final int targetLineupIndex;
+
+  /// Quantité de soin plate réellement portée par cette action.
+  ///
+  /// Lot 9-e reste borné à la vraie `Potion` locale ; ce champ n'ouvre pas
+  /// un catalogue d'effets d'items.
+  final int healAmount;
+}
+
 /// Perdre honnêtement son tour à cause d'une recharge forcée.
 ///
 /// BE8 préfère une action explicite plutôt que de tordre `BattleActionFight`
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart

```diff
diff --git a/packages/map_battle/lib/src/battle_queue.dart b/packages/map_battle/lib/src/battle_queue.dart
index a8d93814..69d1c63b 100644
--- a/packages/map_battle/lib/src/battle_queue.dart
+++ b/packages/map_battle/lib/src/battle_queue.dart
@@ -13,7 +13,7 @@ import 'battle_topology.dart';
 ///
 /// Son rôle est uniquement de devenir la vraie source de vérité du scheduling
 /// interne du tour :
-/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`) ;
+/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`, `Potion`) ;
 /// - de la fin de tour ;
 /// - des checks post-résolution ;
 /// - des remplacements déjà honnêtement supportés.
@@ -86,6 +86,7 @@ sealed class BattleQueueStep {
 ///   pseudo commande universelle.
 bool isBattleQueueManagedAction(BattleAction action) {
   return action is BattleActionFight ||
+      action is BattleActionPotionUse ||
       action is BattleActionRecharge ||
       action is BattleActionSwitch;
 }
@@ -107,7 +108,7 @@ final class BattleQueueActionStep extends BattleQueueStep {
       throw ArgumentError.value(
         action,
         'action',
-        'BattleQueueActionStep n’accepte que Fight/Switch/Recharge.',
+        'BattleQueueActionStep n’accepte que Fight/Potion/Switch/Recharge.',
       );
     }
     return BattleQueueActionStep._(
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart

```diff
diff --git a/packages/map_battle/lib/src/battle_resolution.dart b/packages/map_battle/lib/src/battle_resolution.dart
index b78064f0..c173cf7a 100644
--- a/packages/map_battle/lib/src/battle_resolution.dart
+++ b/packages/map_battle/lib/src/battle_resolution.dart
@@ -24,6 +24,7 @@ class BattleTurnResult {
   /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
   /// [stealthRockEvents] - Les événements Stealth Rock visibles du tour.
   /// [spikesEvents] - Les événements Spikes visibles du tour.
+  /// [potionEvents] - Les usages de Potion visibles du tour.
   /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
   const BattleTurnResult({
     required this.playerAction,
@@ -34,6 +35,7 @@ class BattleTurnResult {
     this.fieldEvents = const <BattleFieldEvent>[],
     this.stealthRockEvents = const <BattleStealthRockEvent>[],
     this.spikesEvents = const <BattleSpikesEvent>[],
+    this.potionEvents = const <BattlePotionEvent>[],
     this.switchEvents = const <BattleSwitchEvent>[],
     this.timeline = const <BattleTurnEvent>[],
   });
@@ -96,6 +98,15 @@ class BattleTurnResult {
   /// - ce lot porte donc son propre contrat dédié, vivant et testable.
   final List<BattleSpikesEvent> spikesEvents;
 
+  /// Les usages de Potion visibles pendant ce tour.
+  ///
+  /// Lot 9-e choisit ici un contrat explicitement non générique :
+  /// - ce bucket ne devient pas "itemsEvents" ;
+  /// - il ne couvre ni Antidote, ni Super Potion, ni objets tenus ;
+  /// - il sert uniquement à rendre l'action `Potion` observable quand elle
+  ///   devient une vraie action de tour committée.
+  final List<BattlePotionEvent> potionEvents;
+
   /// Les événements de switch / remplacement visibles pendant ce tour.
   ///
   /// BE10 les sépare volontairement du reste :
@@ -172,12 +183,43 @@ final class BattleTurnSpikesEvent extends BattleTurnEvent {
   final BattleSpikesEvent event;
 }
 
+final class BattleTurnPotionEvent extends BattleTurnEvent {
+  const BattleTurnPotionEvent(this.event);
+
+  final BattlePotionEvent event;
+}
+
 final class BattleTurnSwitchEvent extends BattleTurnEvent {
   const BattleTurnSwitchEvent(this.event);
 
   final BattleSwitchEvent event;
 }
 
+/// Trace visible d'un vrai usage de `Potion` pendant un tour.
+///
+/// Frontière volontairement serrée :
+/// - on ne transporte pas un "itemId" arbitraire ;
+/// - on ne généralise pas vers un journal d'objets battle ;
+/// - on porte seulement les données nécessaires pour raconter honnêtement
+///   l'usage de Potion et la variation réelle de PV.
+final class BattlePotionEvent {
+  const BattlePotionEvent({
+    required this.side,
+    required this.targetLineupIndex,
+    required this.targetSpeciesId,
+    required this.hpBefore,
+    required this.hpAfter,
+  });
+
+  final BattleSideId side;
+  final int targetLineupIndex;
+  final String targetSpeciesId;
+  final int hpBefore;
+  final int hpAfter;
+
+  int get healedAmount => hpAfter - hpBefore;
+}
+
 /// Exécution d'une attaque.
 ///
 /// Représente une attaque qui a été exécutée avec ses effets.
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart

```diff
diff --git a/packages/map_battle/lib/src/battle_session.dart b/packages/map_battle/lib/src/battle_session.dart
index 17688c6d..ad25fbe9 100644
--- a/packages/map_battle/lib/src/battle_session.dart
+++ b/packages/map_battle/lib/src/battle_session.dart
@@ -33,8 +33,7 @@ const BattleConditionEngine _conditionEngine = BattleConditionEngine();
 BattleSession createBattleSession(
   BattleSetup setup, {
   BattleRng rng = const BattleSeededRng(),
-  BattleOpponentPolicy opponentPolicy =
-      const BattleFirstLegalOpponentPolicy(),
+  BattleOpponentPolicy opponentPolicy = const BattleFirstLegalOpponentPolicy(),
 }) {
   final player = _buildBattleCombatantFromData(setup.playerPokemon);
   final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
@@ -269,6 +268,50 @@ class BattleSession {
     );
   }
 
+  /// Commit une vraie action de tour `Potion`.
+  ///
+  /// Lot 9-e refuse ici deux faux raccourcis :
+  /// - continuer l'ancien "patch runtime local" 9-d sans vrai `currentTurn` ;
+  /// - ouvrir un framework générique d'items battle.
+  ///
+  /// Ce seam reste donc volontairement étroit :
+  /// - une seule action publique, spécifique à `Potion` ;
+  /// - ciblage par `lineupIndex` battle déjà stable ;
+  /// - aucun bag, aucune consommation d'objet, aucun catalogue d'items ici ;
+  /// - la consommation réelle du bag reste côté runtime une fois le tour
+  ///   effectivement committé par le moteur.
+  BattleSession applyPotionTurn({
+    required int targetLineupIndex,
+    required int healAmount,
+  }) {
+    final request = decisionRequest;
+    if (request is! BattleTurnChoiceRequest) {
+      throw StateError(
+        'Potion ne peut être engagée que pendant un vrai BattleTurnChoiceRequest '
+        '(request=${request.runtimeType}).',
+      );
+    }
+    if (healAmount <= 0) {
+      throw ArgumentError.value(
+        healAmount,
+        'healAmount',
+        'Potion healAmount must stay strictly positive.',
+      );
+    }
+
+    _requireUsablePotionTarget(
+      side: state.playerSide,
+      targetLineupIndex: targetLineupIndex,
+    );
+
+    return _applyCommittedPlayerAction(
+      playerAction: BattleActionPotionUse(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: healAmount,
+      ),
+    );
+  }
+
   BattleDecisionRequest _buildDecisionRequest() {
     const playerSideId = BattleSideId.player;
     const playerSlot = BattleSlotRef.active(BattleSideId.player);
@@ -615,19 +658,21 @@ class BattleSession {
       );
     }
 
-    // Phase 1: Convertir le choix en action
-    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);
+    // Phase 1: Convertir le choix en action puis laisser le scheduler commun
+    // résoudre le vrai tour. Lot 9-e réutilise ce même seam pour `Potion`
+    // afin d'éviter un faux pipeline parallèle runtime-only.
+    return _applyCommittedPlayerAction(
+      playerAction: forcedPlayerAction ?? _choiceToAction(choice),
+    );
+  }
 
-    // Phase 2: Déterminer l'action de l'ennemi via le seam adverse borné.
+  BattleSession _applyCommittedPlayerAction({
+    required BattleAction playerAction,
+  }) {
+    // Le seam adverse reste inchangé : même policy, même scheduler, même
+    // timeline. Lot 9-e ajoute seulement une nouvelle action joueur bornée.
     final enemyAction = _resolveEnemyAction();
 
-    // R2 consolide ici le seam scheduler déjà vivant sans élargir le slice :
-    // - `applyChoice` reste responsable de la frontière request -> action ;
-    // - la planification locale du tour devient explicite via `_BattleTurnPlan` ;
-    // - la consommation de queue et la reprise vivent désormais dans le
-    //   scheduler dédié plutôt que d'être entassées dans cette méthode ;
-    // - la résolution métier des moves, hazards et conditions reste, elle,
-    //   dans `BattleSession`.
     final turnPlan = _planInitialTurn(
       session: this,
       playerAction: playerAction,
@@ -655,7 +700,6 @@ class BattleSession {
       enemyAction: turnPlan.reportedEnemyAction,
     );
 
-    // Phase 5: Vérifier si le combat est fini
     final outcome = turn.pendingTurn != null
         ? null
         : _determineOutcome(
@@ -664,18 +708,11 @@ class BattleSession {
             turn.field,
           );
 
-    // Phase 6: Créer le nouvel état
     final newState = BattleState(
       phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
       playerSide: turn.playerSide,
       enemySide: turn.enemySide,
       field: turn.field,
-      // On conserve maintenant la trace du dernier tour même s'il termine le
-      // combat :
-      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
-      //   application de statut terminale redeviendraient invisibles ;
-      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
-      //   passent pas par `_resolveTurn`.
       currentTurn: turnResult,
       outcome: outcome,
     );
@@ -728,6 +765,45 @@ class BattleSession {
     );
   }
 
+  _ResolvedPotionUseAction _resolvePotionUseAction({
+    required BattleSideState side,
+    required int targetLineupIndex,
+    required int healAmount,
+  }) {
+    if (side.id != BattleSideId.player) {
+      throw StateError(
+        'BattleActionPotionUse reste limité au côté joueur dans le lot 9-e.',
+      );
+    }
+    if (healAmount <= 0) {
+      throw ArgumentError.value(
+        healAmount,
+        'healAmount',
+        'Potion healAmount must stay strictly positive.',
+      );
+    }
+
+    final targetCombatant = _requireUsablePotionTarget(
+      side: side,
+      targetLineupIndex: targetLineupIndex,
+    );
+    final healedCombatant = targetCombatant.withHeal(healAmount);
+
+    return _ResolvedPotionUseAction(
+      side: _replacePlayerCombatantByLineupIndex(
+        side: side,
+        updatedCombatant: healedCombatant,
+      ),
+      event: BattlePotionEvent(
+        side: side.id,
+        targetLineupIndex: healedCombatant.lineupIndex,
+        targetSpeciesId: healedCombatant.speciesId,
+        hpBefore: targetCombatant.currentHp,
+        hpAfter: healedCombatant.currentHp,
+      ),
+    );
+  }
+
   int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
     for (var i = 0; i < reserve.length; i++) {
       if (!reserve[i].isFainted) {
@@ -911,7 +987,8 @@ class BattleSession {
     return selectedAction;
   }
 
-  List<BattleOpponentReplacementOption> _availableEnemyVoluntarySwitchOptions() {
+  List<BattleOpponentReplacementOption>
+      _availableEnemyVoluntarySwitchOptions() {
     if (state.enemy.isFainted) {
       return const <BattleOpponentReplacementOption>[];
     }
@@ -1692,6 +1769,16 @@ class _ResolvedSwitchAction {
   final BattleSwitchEvent event;
 }
 
+class _ResolvedPotionUseAction {
+  const _ResolvedPotionUseAction({
+    required this.side,
+    required this.event,
+  });
+
+  final BattleSideState side;
+  final BattlePotionEvent event;
+}
+
 class _ResolvedMoveExecution {
   const _ResolvedMoveExecution({
     required this.attacker,
@@ -1802,7 +1889,54 @@ BattleSideState _replacePlayerCombatantByLineupIndex({
     );
   }
 
-  final updatedReserve = List<BattleCombatant>.of(side.reserve, growable: false);
+  final updatedReserve =
+      List<BattleCombatant>.of(side.reserve, growable: false);
   updatedReserve[reserveIndex] = updatedCombatant;
   return side.withReserve(updatedReserve);
 }
+
+BattleCombatant _requireUsablePotionTarget({
+  required BattleSideState side,
+  required int targetLineupIndex,
+}) {
+  final combatant = _findCombatantByLineupIndex(
+    side: side,
+    targetLineupIndex: targetLineupIndex,
+  );
+  if (combatant == null) {
+    throw StateError(
+      'Potion vise un lineupIndex joueur introuvable dans la session courante '
+      '(lineupIndex=$targetLineupIndex).',
+    );
+  }
+  if (combatant.isFainted) {
+    throw StateError(
+      'Potion ne peut pas cibler un combattant joueur K.O. '
+      '(lineupIndex=$targetLineupIndex).',
+    );
+  }
+  if (combatant.currentHp >= combatant.maxHp) {
+    throw StateError(
+      'Potion ne peut pas cibler un combattant déjà full HP '
+      '(lineupIndex=$targetLineupIndex).',
+    );
+  }
+  return combatant;
+}
+
+BattleCombatant? _findCombatantByLineupIndex({
+  required BattleSideState side,
+  required int targetLineupIndex,
+}) {
+  if (side.active.lineupIndex == targetLineupIndex) {
+    return side.active;
+  }
+
+  final reserveIndex = side.reserve.indexWhere(
+    (combatant) => combatant.lineupIndex == targetLineupIndex,
+  );
+  if (reserveIndex == -1) {
+    return null;
+  }
+  return side.reserve[reserveIndex];
+}
```

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart

```diff
diff --git a/packages/map_battle/lib/src/battle_session_scheduler.dart b/packages/map_battle/lib/src/battle_session_scheduler.dart
index dd2e91d8..6c18ca3b 100644
--- a/packages/map_battle/lib/src/battle_session_scheduler.dart
+++ b/packages/map_battle/lib/src/battle_session_scheduler.dart
@@ -269,6 +269,7 @@ BattleTurnResult _buildTurnResultFromContext({
     stealthRockEvents:
         List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
     spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
+    potionEvents: List<BattlePotionEvent>.unmodifiable(turn.potionEvents),
     switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
     timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
   );
@@ -398,7 +399,8 @@ void _executeActionQueueStep({
     turn.fieldEvents.addAll(resolution.fieldEvents);
     turn.timeline.addAll(resolution.timeline);
 
-    final sideConditionResolution = _conditionEngine.runSideConditionMoveResolved(
+    final sideConditionResolution =
+        _conditionEngine.runSideConditionMoveResolved(
       move: move,
       didResolveHit: resolution.execution?.didHit == true,
       targetSide: turn.side(_opposingSideId(step.side)),
@@ -417,20 +419,20 @@ void _executeActionQueueStep({
       reserveIndex: reserveIndex,
       wasForced: step.wasForced,
     );
-  turn.updateSide(step.side, resolution.side);
-  turn.switchEvents.add(resolution.event);
-  turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
+    turn.updateSide(step.side, resolution.side);
+    turn.switchEvents.add(resolution.event);
+    turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
 
-  final entryHazards = _conditionEngine.runEntryHazards(
-    side: turn.side(step.side),
-  );
-  _recordSideConditionResolution(
-    turn: turn,
-    sideId: step.side,
-    resolution: entryHazards,
-  );
+    final entryHazards = _conditionEngine.runEntryHazards(
+      side: turn.side(step.side),
+    );
+    _recordSideConditionResolution(
+      turn: turn,
+      sideId: step.side,
+      resolution: entryHazards,
+    );
 
-  final sideAfterEntry = turn.side(step.side);
+    final sideAfterEntry = turn.side(step.side);
     if (sideAfterEntry.active.isFainted &&
         step.side == BattleSideId.player &&
         session._firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
@@ -443,6 +445,28 @@ void _executeActionQueueStep({
     return;
   }
 
+  if (step.action
+      case BattleActionPotionUse(
+        :final targetLineupIndex,
+        :final healAmount,
+      )) {
+    if (step.side != BattleSideId.player) {
+      throw StateError(
+        'BattleActionPotionUse reste player-only dans le lot 9-e.',
+      );
+    }
+
+    final resolution = session._resolvePotionUseAction(
+      side: actingSide,
+      targetLineupIndex: targetLineupIndex,
+      healAmount: healAmount,
+    );
+    turn.updateSide(step.side, resolution.side);
+    turn.potionEvents.add(resolution.event);
+    turn.timeline.add(BattleTurnPotionEvent(resolution.event));
+    return;
+  }
+
   if (step.action is BattleActionRecharge) {
     if (actingSide.active.isFainted || opposingSide.active.isFainted) {
       return;
@@ -595,8 +619,7 @@ int? _chooseEnemyReplacementIndex({
   }
 
   final selectedOption = session.opponentPolicy.chooseReplacement(
-    legalReplacementOptions:
-        List<BattleOpponentReplacementOption>.unmodifiable(
+    legalReplacementOptions: List<BattleOpponentReplacementOption>.unmodifiable(
       legalReplacementOptions,
     ),
   );
@@ -788,6 +811,12 @@ int _priorityForResolvedAction(BattleAction action) {
     // - un switch volontaire ou forcé résout avant un `Fight` standard ;
     // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
     //   des priorités de switch.
+    //
+    // Lot 9-e ajoute un seul cas de plus :
+    // - `Potion` doit devenir une vraie action de tour ;
+    // - elle résout avant les moves actuellement supportés ;
+    // - on refuse pourtant d'ouvrir une échelle générique de priorités items.
+    BattleActionPotionUse() => 7,
     BattleActionSwitch() => 6,
     BattleActionFight(:final move) => move.priority,
     BattleActionRecharge() => 0,
@@ -821,6 +850,7 @@ final class _PendingTurnContinuation {
     required this.fieldEvents,
     required this.stealthRockEvents,
     required this.spikesEvents,
+    required this.potionEvents,
     required this.switchEvents,
     required this.timeline,
   });
@@ -848,6 +878,7 @@ final class _PendingTurnContinuation {
       stealthRockEvents:
           List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
       spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
+      potionEvents: List<BattlePotionEvent>.unmodifiable(turn.potionEvents),
       switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
       timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
     );
@@ -867,6 +898,7 @@ final class _PendingTurnContinuation {
   final List<BattleFieldEvent> fieldEvents;
   final List<BattleStealthRockEvent> stealthRockEvents;
   final List<BattleSpikesEvent> spikesEvents;
+  final List<BattlePotionEvent> potionEvents;
   final List<BattleSwitchEvent> switchEvents;
   final List<BattleTurnEvent> timeline;
 }
@@ -904,6 +936,7 @@ final class _QueuedTurnContext {
       ..fieldEvents.addAll(pending.fieldEvents)
       ..stealthRockEvents.addAll(pending.stealthRockEvents)
       ..spikesEvents.addAll(pending.spikesEvents)
+      ..potionEvents.addAll(pending.potionEvents)
       ..switchEvents.addAll(pending.switchEvents)
       ..timeline.addAll(pending.timeline);
   }
@@ -924,6 +957,7 @@ final class _QueuedTurnContext {
   final List<BattleStealthRockEvent> stealthRockEvents =
       <BattleStealthRockEvent>[];
   final List<BattleSpikesEvent> spikesEvents = <BattleSpikesEvent>[];
+  final List<BattlePotionEvent> potionEvents = <BattlePotionEvent>[];
   final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
   final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];
 
```

### /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart

```diff
diff --git a/packages/map_battle/test/battle_session_test.dart b/packages/map_battle/test/battle_session_test.dart
index 847046ec..22ff0c75 100644
--- a/packages/map_battle/test/battle_session_test.dart
+++ b/packages/map_battle/test/battle_session_test.dart
@@ -943,5 +943,140 @@ void main() {
       // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
       expect(session.state.outcome!.isVictory, isTrue);
     });
+
+    test(
+        'applyPotionTurn commits a real turn and the enemy still responds in the same turn flow',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 40,
+            currentHp: 12,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
+            ],
+          ),
+          enemyPokemon: const BattleCombatantData(
+            speciesId: 'sparkitten',
+            level: 10,
+            maxHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(
+                id: 'wait',
+                name: 'Wait',
+                power: 0,
+                category: BattleMoveCategory.status,
+                target: BattleMoveTarget.self,
+                accuracy: BattleMoveAccuracy.alwaysHits(),
+              ),
+            ],
+          ),
+          isTrainerBattle: true,
+          trainerId: 'trainer_1',
+        ),
+      );
+
+      final updatedSession = session.applyPotionTurn(
+        targetLineupIndex: 0,
+        healAmount: 20,
+      );
+
+      expect(updatedSession.state.currentTurn, isNotNull);
+      expect(updatedSession.state.player.currentHp, equals(32));
+      expect(
+        updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionPotionUse>(),
+      );
+      expect(
+        updatedSession.state.currentTurn!.enemyAction,
+        isA<BattleActionFight>(),
+      );
+      expect(updatedSession.state.currentTurn!.potionEvents, hasLength(1));
+      expect(
+        updatedSession.state.currentTurn!.potionEvents.single.healedAmount,
+        equals(20),
+      );
+      expect(
+        updatedSession.state.currentTurn!.timeline.first,
+        isA<BattleTurnPotionEvent>(),
+      );
+      expect(
+        updatedSession.state.currentTurn!.timeline.last,
+        isA<BattleTurnExecutionEvent>(),
+      );
+      expect(
+        updatedSession.decisionRequest,
+        isA<BattleTurnChoiceRequest>(),
+      );
+    });
+
+    test(
+        'applyPotionTurn rejects invalid targets instead of faking a committed item turn',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 40,
+            currentHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
+            ],
+          ),
+          playerReservePokemon: const <BattleCombatantData>[
+            BattleCombatantData(
+              speciesId: 'benchmate',
+              level: 10,
+              maxHp: 35,
+              currentHp: 0,
+              lineupIndex: 1,
+              stats: _neutralBattleStats,
+              moves: <BattleMoveData>[
+                BattleMoveData(id: 'wait', name: 'Wait', power: 0),
+              ],
+            ),
+          ],
+          enemyPokemon: const BattleCombatantData(
+            speciesId: 'sparkitten',
+            level: 10,
+            maxHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'wait', name: 'Wait', power: 0),
+            ],
+          ),
+          isTrainerBattle: true,
+          trainerId: 'trainer_1',
+        ),
+      );
+
+      expect(
+        () => session.applyPotionTurn(
+          targetLineupIndex: 0,
+          healAmount: 20,
+        ),
+        throwsA(isA<StateError>()),
+      );
+      expect(
+        () => session.applyPotionTurn(
+          targetLineupIndex: 1,
+          healAmount: 20,
+        ),
+        throwsA(isA<StateError>()),
+      );
+      expect(session.state.currentTurn, isNull);
+      expect(session.state.player.currentHp, equals(40));
+      expect(session.state.playerReserve.single.currentHp, equals(0));
+    });
   });
 }
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart

```diff
diff --git a/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart b/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
index 129836bb..8cb39411 100644
--- a/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
+++ b/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
@@ -177,10 +177,10 @@ GameState applyRuntimeBattleOutcomeToGameState({
   required BattleOutcome outcome,
   StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
 }) {
-  final stateWithPlayerHp = _writePlayerBattleLineupBackToPartySlots(
+  final stateWithPlayerHp = writePlayerBattleLineupBackToPartySlots(
     gameState: gameState,
     context: context,
-    finalState: outcome.finalState,
+    battleState: outcome.finalState,
   );
 
   final request = context.request;
@@ -330,14 +330,14 @@ Bag _consumeOnePokeBallOrThrow(Bag bag) {
 /// - on n'écrit encore que les PV, car le runtime hors combat ne possède pas
 ///   encore de write-back honnête des PP courants ni des statuts majeurs ;
 /// - les membres de party non engagés dans ce combat restent inchangés.
-GameState _writePlayerBattleLineupBackToPartySlots({
+GameState writePlayerBattleLineupBackToPartySlots({
   required GameState gameState,
   required RuntimeActiveBattleContext context,
-  required BattleState finalState,
+  required BattleState battleState,
 }) {
   final playerLineup = <BattleCombatant>[
-    finalState.player,
-    ...finalState.playerReserve,
+    battleState.player,
+    ...battleState.playerReserve,
   ];
   final hasExplicitLineupMapping =
       context.playerPartySlotIndicesByLineupIndex.isNotEmpty;
@@ -352,13 +352,13 @@ GameState _writePlayerBattleLineupBackToPartySlots({
   // - on préfère donc un échec explicite et testable à une écriture silencieuse
   //   sur le mauvais membre de la party.
   if (!hasExplicitLineupMapping &&
-      (playerLineup.length > 1 || finalState.player.lineupIndex != 0)) {
+      (playerLineup.length > 1 || battleState.player.lineupIndex != 0)) {
     throw StateError(
       'Le write-back runtime BE10 exige RuntimeActiveBattleContext.'
       'playerPartySlotIndicesByLineupIndex quand BattleOutcome.finalState '
       'porte une lineup joueur multi-membre ou non triviale '
       '(lineupLength=${playerLineup.length}, '
-      'activeLineupIndex=${finalState.player.lineupIndex}).',
+      'activeLineupIndex=${battleState.player.lineupIndex}).',
     );
   }
 
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart

```diff
diff --git a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart b/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
index 2af94ea1..e1709637 100644
--- a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
+++ b/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
@@ -23,11 +23,11 @@ class RuntimeBattlePotionApplyResult {
   final int healedAmount;
 }
 
-// Lot 9-d reste volontairement borné :
-// - aucun contrat générique d'items battle ;
-// - aucune action map_battle nouvelle ;
-// - juste l'application runtime immédiate de Potion sur la lineup battle
-//   courante et sur le vrai GameState.
+// Lot 9-e absorbe l'ancien apply local 9-d dans un vrai commit de tour :
+// - `map_battle` résout maintenant un vrai `currentTurn` spécifique à Potion ;
+// - ce helper reste pourtant runtime-only pour le bag et le write-back party ;
+// - on n'ouvre toujours aucun système générique d'items battle ;
+// - on ne fabrique jamais de `PlayerBattleChoiceUseItem`.
 RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
   required BattleSession session,
   required GameState gameState,
@@ -52,17 +52,21 @@ RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
     return null;
   }
 
-  final healedCombatant = targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
+  final healedCombatant =
+      targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
   final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
   if (healedAmount <= 0) {
     return null;
   }
 
-  final updatedSession = session.withUpdatedPlayerCombatant(healedCombatant);
-  final updatedGameState = _applyPotionToRuntimeState(
+  final updatedSession = session.applyPotionTurn(
+    targetLineupIndex: targetLineupIndex,
+    healAmount: _runtimeBattlePotionHealAmount,
+  );
+  final updatedGameState = _applyCommittedPotionTurnToRuntimeState(
     gameState: gameState,
     context: context,
-    healedCombatant: healedCombatant,
+    updatedSession: updatedSession,
   );
 
   return RuntimeBattlePotionApplyResult(
@@ -90,71 +94,25 @@ BattleCombatant? _findPlayerCombatantByLineupIndex({
   return null;
 }
 
-// Le write-back lot 9-d ne touche que :
-// - le slot de party runtime exactement aligné sur le lineup battle ciblé ;
-// - la consommation d'une seule Potion ;
-// - rien d'autre dans le save runtime.
-GameState _applyPotionToRuntimeState({
+// Lot 9-e écrit désormais la vraie vérité runtime après un tour committé :
+// - toute la lineup battle joueur engagée est réécrite sur la vraie party ;
+// - la Potion est consommée exactement une fois après un commit battle réussi ;
+// - aucun faux "state overlay only" ne survit.
+GameState _applyCommittedPotionTurnToRuntimeState({
   required GameState gameState,
   required RuntimeActiveBattleContext context,
-  required BattleCombatant healedCombatant,
+  required BattleSession updatedSession,
 }) {
-  final partyIndex = _resolvePlayerPartySlotIndex(
+  final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
+    gameState: gameState,
     context: context,
-    targetLineupIndex: healedCombatant.lineupIndex,
-    partyLength: gameState.party.members.length,
+    battleState: updatedSession.state,
   );
-  final members = List<PlayerPokemon>.of(gameState.party.members, growable: false);
-  final currentMember = members[partyIndex];
-  members[partyIndex] = currentMember.copyWith(currentHp: healedCombatant.currentHp);
-
-  return gameState.copyWith(
-    party: gameState.party.copyWith(members: members),
-    bag: _consumeOnePotionOrThrow(gameState.bag),
+  return withCommittedHp.copyWith(
+    bag: _consumeOnePotionOrThrow(withCommittedHp.bag),
   );
 }
 
-int _resolvePlayerPartySlotIndex({
-  required RuntimeActiveBattleContext context,
-  required int targetLineupIndex,
-  required int partyLength,
-}) {
-  if (context.playerPartySlotIndicesByLineupIndex.isEmpty) {
-    if (targetLineupIndex != 0) {
-      throw StateError(
-        'Lot 9-d ne peut pas cibler honnêtement une réserve sans mapping lineup->party runtime.',
-      );
-    }
-    if (context.playerPartyIndex < 0 || context.playerPartyIndex >= partyLength) {
-      throw StateError(
-        'Lot 9-d a reçu un playerPartyIndex runtime invalide: '
-        'index=${context.playerPartyIndex}, partyLength=$partyLength',
-      );
-    }
-    return context.playerPartyIndex;
-  }
-
-  if (targetLineupIndex < 0 ||
-      targetLineupIndex >= context.playerPartySlotIndicesByLineupIndex.length) {
-    throw StateError(
-      'Lot 9-d a reçu un lineupIndex battle invalide pour Potion: '
-      'lineupIndex=$targetLineupIndex, '
-      'mappingLength=${context.playerPartySlotIndicesByLineupIndex.length}',
-    );
-  }
-
-  final partyIndex =
-      context.playerPartySlotIndicesByLineupIndex[targetLineupIndex];
-  if (partyIndex < 0 || partyIndex >= partyLength) {
-    throw StateError(
-      'Lot 9-d a reçu un mapping lineup->party invalide pour Potion: '
-      'lineupIndex=$targetLineupIndex, partyIndex=$partyIndex, '
-      'partyLength=$partyLength',
-    );
-  }
-  return partyIndex;
-}
-
 bool _hasPotionAvailable(Bag bag) {
   for (final entry in bag.normalized().entries) {
     if (entry.itemId == _runtimeBattlePotionItemId &&
@@ -189,7 +147,8 @@ Bag _consumeOnePotionOrThrow(Bag bag) {
   }
 
   if (!consumed) {
-    throw StateError('Impossible de consommer Potion : aucune entrée potion disponible.');
+    throw StateError(
+        'Impossible de consommer Potion : aucune entrée potion disponible.');
   }
 
   return Bag(entries: nextEntries).normalized();
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
index 23d1d136..661a96d0 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
@@ -21,7 +21,6 @@ import 'battle_scene_backdrop_component.dart';
 import 'battle_scene_combatant_component.dart';
 import 'battle_scene_hud_component.dart';
 import 'battle_turn_presentation.dart';
-import '../../application/runtime_battle_potion_apply.dart';
 
 /// Retourne le prompt de décision à afficher pour la requête courante.
 ///
@@ -57,6 +56,7 @@ List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
           turnResult.fieldEvents.isNotEmpty ||
           turnResult.stealthRockEvents.isNotEmpty ||
           turnResult.spikesEvents.isNotEmpty ||
+          turnResult.potionEvents.isNotEmpty ||
           turnResult.switchEvents.isNotEmpty)) {
     throw StateError(
       'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
@@ -66,6 +66,10 @@ List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
   final lines = <String>[];
   for (final event in turnResult.timeline) {
     switch (event) {
+      case BattleTurnPotionEvent(:final event):
+        final actor = _overlayCombatantLabelForSide(event.side);
+        lines.add('$actor utilise Potion sur ${event.targetSpeciesId}');
+        lines.add('${event.targetSpeciesId} récupère ${event.healedAmount} PV');
       case BattleTurnExecutionEvent(:final execution):
         final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
         lines.add(
@@ -375,8 +379,7 @@ class BattleOverlayComponent extends PositionComponent {
   GameState _gameState;
 
   final void Function(PlayerBattleChoice choice) onPlayerChoice;
-  final RuntimeBattlePotionApplyResult? Function(BattleMedicineTargetEntry entry)?
-      onPotionUseRequested;
+  final bool Function(BattleMedicineTargetEntry entry)? onPotionUseRequested;
   final BattleBackgroundSpec backgroundSpec;
   final BattlePokemonSpriteResolver? spriteResolver;
   final BattleVisualAssetCache? visualAssetCache;
@@ -1085,39 +1088,17 @@ class BattleOverlayComponent extends PositionComponent {
       return false;
     }
     final selectedMedicineAction = _selectedMedicineAction;
-    if (selectedMedicineAction == null || selectedMedicineAction.itemId != 'potion') {
-      return false;
-    }
-    // Lot 9-d garde ce handler volontairement borné :
-    // - il ne synthétise toujours aucun PlayerBattleChoice item ;
-    // - il ne crée aucun contrat générique d’objets battle ;
-    // - il reflète seulement un effet runtime déjà appliqué par le parent,
-    //   propriétaire du vrai BattleSession et du vrai GameState.
-    final applyResult = onPotionUseRequested?.call(entry);
-    if (applyResult == null) {
+    if (selectedMedicineAction == null ||
+        selectedMedicineAction.itemId != 'potion') {
       return false;
     }
 
-    final previousSession = _session;
-    _session = applyResult.updatedSession;
-    _gameState = applyResult.updatedGameState;
-    _selectedMedicineAction = null;
-    _selectedMedicineTargetIndex = 0;
-    _bagFeedbackMessage =
-        '${applyResult.targetSpeciesId} récupère ${applyResult.healedAmount} PV.';
-
-    // Choix UX lot 9-d :
-    // - on revient au BAG après un usage réussi ;
-    // - on garde le feedback de succès sur un écran encore pertinent ;
-    // - on évite de laisser le curseur sur une cible devenue full HP ;
-    // - on n'invente toujours aucun tour "item" dans le moteur battle.
-    final bagMenuModel = _currentBagMenuModel();
-    _menuMode = BattleCommandMenuMode.bag;
-    _selectedBagIndex = _firstSelectableBagIndexFor(bagMenuModel);
-    _syncPanelsOnly();
-    _pendingVisualSync = _syncVisualState(previousSession: previousSession);
-    unawaited(_pendingVisualSync);
-    return true;
+    // Lot 9-e change volontairement le propriétaire de l'effet réel :
+    // - le parent runtime commit maintenant un vrai tour `Potion` ;
+    // - l'overlay ne patche plus sa session localement ;
+    // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
+    //   propriétaire unique du vrai BattleSession / GameState.
+    return onPotionUseRequested?.call(entry) ?? false;
   }
 
   void _handleBagEntrySelected(BattleBagMenuEntry entry) {
@@ -1513,7 +1494,7 @@ class BattleOverlayComponent extends PositionComponent {
           : _turnPresentationSteps[_turnPresentationIndex];
 
   double _durationForPresentationStep(BattleTurnPresentationStep step) {
-    return step.animatesDamage
+    return step.animatesHpChange
         ? _presentationImpactStepSeconds
         : _presentationMessageOnlyStepSeconds;
   }
@@ -1530,7 +1511,7 @@ class BattleOverlayComponent extends PositionComponent {
   }
 
   void _applyTurnPresentationEffect(BattleTurnPresentationStep step) {
-    final targetSide = step.flashTargetSide;
+    final targetSide = step.hpChangeTargetSide;
     final hpFrom = step.hpFrom;
     final hpTo = step.hpTo;
     if (targetSide == null || hpFrom == null || hpTo == null) {
@@ -1539,7 +1520,9 @@ class BattleOverlayComponent extends PositionComponent {
     final isPlayerSide = targetSide == BattleSideId.player;
     final combatant = isPlayerSide ? _playerCombatant : _enemyCombatant;
     final hud = isPlayerSide ? _playerHud : _enemyHud;
-    combatant?.triggerHitFlash();
+    if (step.flashTargetSide == targetSide) {
+      combatant?.triggerHitFlash();
+    }
     hud?.animateDisplayedHp(fromHp: hpFrom, toHp: hpTo);
   }
 
@@ -1549,7 +1532,8 @@ class BattleOverlayComponent extends PositionComponent {
   }) {
     if (previousSession == null ||
         !isTurnPresentationActive ||
-        !_turnPresentationSteps.any((step) => step.flashTargetSide == side)) {
+        !_turnPresentationSteps
+            .any((step) => step.hpChangeTargetSide == side)) {
       return null;
     }
     final previousCombatant = side == BattleSideId.player
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart b/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
index 9ec0e8a0..c7658682 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
@@ -4,17 +4,21 @@ class BattleTurnPresentationStep {
   const BattleTurnPresentationStep({
     required this.message,
     this.flashTargetSide,
+    this.hpChangeTargetSide,
     this.hpFrom,
     this.hpTo,
   });
 
   final String message;
   final BattleSideId? flashTargetSide;
+  final BattleSideId? hpChangeTargetSide;
   final int? hpFrom;
   final int? hpTo;
 
-  bool get animatesDamage =>
-      flashTargetSide != null && hpFrom != null && hpTo != null;
+  bool get animatesHpChange =>
+      hpChangeTargetSide != null && hpFrom != null && hpTo != null;
+
+  bool get animatesDamage => flashTargetSide != null && animatesHpChange;
 }
 
 List<BattleTurnPresentationStep> buildBattleTurnPresentationSteps({
@@ -29,35 +33,71 @@ List<BattleTurnPresentationStep> buildBattleTurnPresentationSteps({
   final steps = <BattleTurnPresentationStep>[];
 
   for (final event in turnResult.timeline) {
-    if (event is! BattleTurnExecutionEvent) {
-      continue;
-    }
+    switch (event) {
+      case BattleTurnPotionEvent(:final event):
+        final userLabel = _presentationCombatantLabel(event.side);
+        steps.add(
+          BattleTurnPresentationStep(
+            message: '$userLabel utilise Potion sur ${event.targetSpeciesId} !',
+          ),
+        );
 
-    final execution = event.execution;
-    final message =
-        '${_presentationCombatantLabel(execution.attackerSide)} utilise ${execution.move.name} !';
-    final targetSide = execution.targetSide;
-    final dealsVisibleDamage = execution.didHit &&
-        execution.damage > 0 &&
-        execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
-        targetSide != null;
+        final visibleTargetSide = event.side == BattleSideId.player &&
+                playerBefore.lineupIndex == event.targetLineupIndex
+            ? BattleSideId.player
+            : event.side == BattleSideId.enemy &&
+                    enemyBefore.lineupIndex == event.targetLineupIndex
+                ? BattleSideId.enemy
+                : null;
+        if (visibleTargetSide == null || event.healedAmount <= 0) {
+          steps.add(
+            BattleTurnPresentationStep(
+              message:
+                  '${event.targetSpeciesId} récupère ${event.healedAmount} PV.',
+            ),
+          );
+          continue;
+        }
 
-    if (!dealsVisibleDamage) {
-      steps.add(BattleTurnPresentationStep(message: message));
-      continue;
-    }
+        trackedHp[visibleTargetSide] = event.hpAfter;
+        steps.add(
+          BattleTurnPresentationStep(
+            message:
+                '${event.targetSpeciesId} récupère ${event.healedAmount} PV.',
+            hpChangeTargetSide: visibleTargetSide,
+            hpFrom: event.hpBefore,
+            hpTo: event.hpAfter,
+          ),
+        );
+      case BattleTurnExecutionEvent(:final execution):
+        final message =
+            '${_presentationCombatantLabel(execution.attackerSide)} utilise ${execution.move.name} !';
+        final targetSide = execution.targetSide;
+        final dealsVisibleDamage = execution.didHit &&
+            execution.damage > 0 &&
+            execution.targetKind == BattleMoveExecutionTargetKind.combatant &&
+            targetSide != null;
 
-    final hpFrom = trackedHp[targetSide] ?? 0;
-    final hpTo = (hpFrom - execution.damage).clamp(0, hpFrom);
-    trackedHp[targetSide] = hpTo;
-    steps.add(
-      BattleTurnPresentationStep(
-        message: message,
-        flashTargetSide: targetSide,
-        hpFrom: hpFrom,
-        hpTo: hpTo,
-      ),
-    );
+        if (!dealsVisibleDamage) {
+          steps.add(BattleTurnPresentationStep(message: message));
+          continue;
+        }
+
+        final hpFrom = trackedHp[targetSide] ?? 0;
+        final hpTo = (hpFrom - execution.damage).clamp(0, hpFrom);
+        trackedHp[targetSide] = hpTo;
+        steps.add(
+          BattleTurnPresentationStep(
+            message: message,
+            flashTargetSide: targetSide,
+            hpChangeTargetSide: targetSide,
+            hpFrom: hpFrom,
+            hpTo: hpTo,
+          ),
+        );
+      default:
+        continue;
+    }
   }
 
   return List<BattleTurnPresentationStep>.unmodifiable(steps);
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 1b268db3..3089d31b 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -387,7 +387,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   GridPos get debugPlayerGridPosition => _world.player.pos;
 
   @visibleForTesting
-  bool get debugHasActiveScenarioFollow => _pendingScenarioFollowRequest != null;
+  bool get debugHasActiveScenarioFollow =>
+      _pendingScenarioFollowRequest != null;
 
   @visibleForTesting
   String? get debugScenarioFollowLeaderId =>
@@ -3368,7 +3369,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
         )) {
           return false;
         }
-        final trial = followWorld.withPlayer(followWorld.player.copyWith(pos: cell));
+        final trial =
+            followWorld.withPlayer(followWorld.player.copyWith(pos: cell));
         return !trial.isBlocked(x, y);
       },
     );
@@ -3571,7 +3573,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     if (normalized.isEmpty) {
       return _world;
     }
-    final index = _world.map.entities.indexWhere((entity) => entity.id == normalized);
+    final index =
+        _world.map.entities.indexWhere((entity) => entity.id == normalized);
     if (index < 0) {
       return _world;
     }
@@ -3969,33 +3972,53 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
   }
 
-  RuntimeBattlePotionApplyResult? _onBattlePotionUseRequested(
+  bool _onBattlePotionUseRequested(
     BattleMedicineTargetEntry entry,
   ) {
     final battleSession = _battleSession;
     final activeBattleContext = _activeBattleContext;
     if (battleSession == null || activeBattleContext == null) {
-      return null;
+      return false;
     }
 
-    // Lot 9-d garde l’effet de Potion entièrement côté runtime :
-    // - aucun PlayerBattleChoice item ;
-    // - aucun système générique d’objets battle ;
-    // - la mutation réelle porte seulement sur la session courante et le
-    //   GameState possédés ici, puis l’overlay se resynchronise dessus.
-    final result = tryApplyRuntimeBattlePotionUse(
-      session: battleSession,
-      gameState: _gameState,
-      context: activeBattleContext,
-      targetLineupIndex: entry.lineupIndex,
-    );
-    if (result == null) {
-      return null;
+    if (_isBattleResolving) {
+      debugPrint('[battle] potion ignored: already resolving');
+      return false;
     }
 
-    _battleSession = result.updatedSession;
-    _gameState = result.updatedGameState;
-    return result;
+    _isBattleResolving = true;
+    try {
+      // Lot 9-e fait maintenant passer Potion par un vrai commit de tour :
+      // - le moteur battle produit un `currentTurn` et une timeline honnêtes ;
+      // - le runtime reste propriétaire du bag réel et du write-back party ;
+      // - on n'ouvre toujours aucun PlayerBattleChoice item générique.
+      final result = tryApplyRuntimeBattlePotionUse(
+        session: battleSession,
+        gameState: _gameState,
+        context: activeBattleContext,
+        targetLineupIndex: entry.lineupIndex,
+      );
+      if (result == null) {
+        return false;
+      }
+
+      _battleSession = result.updatedSession;
+      _gameState = result.updatedGameState;
+      _battleOverlay?.updateState(
+        _battleSession!,
+        gameState: _gameState,
+      );
+
+      if (_battleSession!.state.isFinished) {
+        _onBattleFinished(_battleSession!.state.outcome!);
+      }
+
+      return true;
+    } finally {
+      if (_flowPhase == _RuntimeFlowPhase.battle) {
+        _isBattleResolving = false;
+      }
+    }
   }
 
   /// Gère la fin du combat.
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart

```diff
diff --git a/packages/map_runtime/test/battle_overlay_component_test.dart b/packages/map_runtime/test/battle_overlay_component_test.dart
index 1be4bf80..f793cc7b 100644
--- a/packages/map_runtime/test/battle_overlay_component_test.dart
+++ b/packages/map_runtime/test/battle_overlay_component_test.dart
@@ -1290,7 +1290,7 @@ void main() {
     });
 
     test(
-        'selecting a valid medicine target heals immediately, consumes one potion, and does not dispatch a PlayerBattleChoice',
+        'selecting a valid medicine target commits a real potion turn without dispatching a PlayerBattleChoice',
         () async {
       PlayerBattleChoice? pickedChoice;
       final session = _session(
@@ -1313,7 +1313,7 @@ void main() {
         enemy: _combatant(
           speciesId: 'wild_enemy',
           lineupIndex: 0,
-          moves: <BattleMoveData>[_tackle()],
+          moves: <BattleMoveData>[_waitingMove()],
         ),
       );
       final gameState = _gameState(
@@ -1333,28 +1333,38 @@ void main() {
         gameState: gameState,
         viewportSize: Vector2(960, 540),
         onPlayerChoice: (choice) => pickedChoice = choice,
-        onPotionUseRequested: (entry) => tryApplyRuntimeBattlePotionUse(
-          session: overlay.debugSession,
-          gameState: overlay.debugGameState,
-          context: const RuntimeActiveBattleContext(
-            request: TrainerBattleStartRequest(
-              requestId: 'trainer-request',
-              createdAtEpochMs: 1,
-              returnContext: OverworldReturnContext(
+        onPotionUseRequested: (entry) {
+          final result = tryApplyRuntimeBattlePotionUse(
+            session: overlay.debugSession,
+            gameState: overlay.debugGameState,
+            context: const RuntimeActiveBattleContext(
+              request: TrainerBattleStartRequest(
+                requestId: 'trainer-request',
+                createdAtEpochMs: 1,
+                returnContext: OverworldReturnContext(
+                  mapId: 'field_map',
+                  playerPos: GridPos(x: 1, y: 1),
+                  playerFacing: Direction.north,
+                ),
+                trainerId: 'trainer',
+                npcEntityId: 'npc_trainer',
                 mapId: 'field_map',
                 playerPos: GridPos(x: 1, y: 1),
-                playerFacing: Direction.north,
               ),
-              trainerId: 'trainer',
-              npcEntityId: 'npc_trainer',
-              mapId: 'field_map',
-              playerPos: GridPos(x: 1, y: 1),
+              playerPartyIndex: 0,
+              playerPartySlotIndicesByLineupIndex: <int>[0, 1],
             ),
-            playerPartyIndex: 0,
-            playerPartySlotIndicesByLineupIndex: <int>[0, 1],
-          ),
-          targetLineupIndex: entry.lineupIndex,
-        ),
+            targetLineupIndex: entry.lineupIndex,
+          );
+          if (result == null) {
+            return false;
+          }
+          overlay.updateState(
+            result.updatedSession,
+            gameState: result.updatedGameState,
+          );
+          return true;
+        },
       );
 
       await overlay.onLoad();
@@ -1365,24 +1375,31 @@ void main() {
 
       expect(overlay.validateSelectedChoice(), isTrue);
 
-      final commandPanel =
-          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      await overlay.waitForPendingVisualSync();
+
       expect(pickedChoice, isNull);
+      expect(overlay.debugSession.state.currentTurn, isNotNull);
+      expect(
+        overlay.debugSession.state.currentTurn!.playerAction,
+        isA<BattleActionPotionUse>(),
+      );
       expect(overlay.debugSession.state.player.currentHp, equals(32));
       expect(overlay.debugGameState.party.members.first.currentHp, equals(32));
       expect(overlay.debugGameState.bag.entries, isEmpty);
+      expect(overlay.isTurnPresentationActive, isTrue);
       expect(
         overlay.currentPromptText,
-        equals('sproutle récupère 20 PV.'),
+        equals('Joueur utilise Potion sur sproutle !'),
       );
       expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
-      expect(
-        commandPanel.currentBagEntryLabels,
-        isEmpty,
-      );
+      expect(overlay.validateSelectedChoice(), isFalse);
+
+      overlay.updateTree(0.50);
+      expect(overlay.currentPromptText, equals('sproutle récupère 20 PV.'));
     });
 
-    test('selecting a reserve medicine target heals it and updates visible hp',
+    test(
+        'selecting a reserve medicine target commits a real potion turn and updates runtime state',
         () async {
       PlayerBattleChoice? pickedChoice;
       late BattleOverlayComponent overlay;
@@ -1407,7 +1424,7 @@ void main() {
           enemy: _combatant(
             speciesId: 'wild_enemy',
             lineupIndex: 0,
-            moves: <BattleMoveData>[_tackle()],
+            moves: <BattleMoveData>[_waitingMove()],
           ),
         ),
         gameState: _gameState(
@@ -1423,28 +1440,38 @@ void main() {
         ),
         viewportSize: Vector2(960, 540),
         onPlayerChoice: (choice) => pickedChoice = choice,
-        onPotionUseRequested: (entry) => tryApplyRuntimeBattlePotionUse(
-          session: overlay.debugSession,
-          gameState: overlay.debugGameState,
-          context: const RuntimeActiveBattleContext(
-            request: TrainerBattleStartRequest(
-              requestId: 'trainer-request',
-              createdAtEpochMs: 1,
-              returnContext: OverworldReturnContext(
+        onPotionUseRequested: (entry) {
+          final result = tryApplyRuntimeBattlePotionUse(
+            session: overlay.debugSession,
+            gameState: overlay.debugGameState,
+            context: const RuntimeActiveBattleContext(
+              request: TrainerBattleStartRequest(
+                requestId: 'trainer-request',
+                createdAtEpochMs: 1,
+                returnContext: OverworldReturnContext(
+                  mapId: 'field_map',
+                  playerPos: GridPos(x: 1, y: 1),
+                  playerFacing: Direction.north,
+                ),
+                trainerId: 'trainer',
+                npcEntityId: 'npc_trainer',
                 mapId: 'field_map',
                 playerPos: GridPos(x: 1, y: 1),
-                playerFacing: Direction.north,
               ),
-              trainerId: 'trainer',
-              npcEntityId: 'npc_trainer',
-              mapId: 'field_map',
-              playerPos: GridPos(x: 1, y: 1),
+              playerPartyIndex: 0,
+              playerPartySlotIndicesByLineupIndex: <int>[1, 0],
             ),
-            playerPartyIndex: 0,
-            playerPartySlotIndicesByLineupIndex: <int>[1, 0],
-          ),
-          targetLineupIndex: entry.lineupIndex,
-        ),
+            targetLineupIndex: entry.lineupIndex,
+          );
+          if (result == null) {
+            return false;
+          }
+          overlay.updateState(
+            result.updatedSession,
+            gameState: result.updatedGameState,
+          );
+          return true;
+        },
       );
 
       await overlay.onLoad();
@@ -1456,9 +1483,14 @@ void main() {
 
       expect(overlay.validateSelectedChoice(), isTrue);
 
-      final commandPanel =
-          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      await overlay.waitForPendingVisualSync();
+
       expect(pickedChoice, isNull);
+      expect(overlay.debugSession.state.currentTurn, isNotNull);
+      expect(
+        overlay.debugSession.state.currentTurn!.playerAction,
+        isA<BattleActionPotionUse>(),
+      );
       expect(overlay.debugSession.state.player.currentHp, equals(22));
       expect(
         overlay.debugSession.state.playerReserve.single.currentHp,
@@ -1466,8 +1498,8 @@ void main() {
       );
       expect(overlay.debugGameState.party.members[0].currentHp, equals(22));
       expect(overlay.debugGameState.party.members[1].currentHp, equals(40));
-      expect(commandPanel.currentBagEntryLabels, const <String>['Potion x1']);
-      expect(overlay.currentPromptText, equals('benchmate récupère 5 PV.'));
+      expect(overlay.currentPromptText,
+          equals('Joueur utilise Potion sur benchmate !'));
       expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
     });
 
@@ -1575,7 +1607,8 @@ void main() {
         const <String>['Actif', 'K.O.'],
       );
       expect(overlay.validateSelectedChoice(), isFalse);
-      expect(overlay.debugSession.state.playerReserve.single.currentHp, equals(0));
+      expect(
+          overlay.debugSession.state.playerReserve.single.currentHp, equals(0));
       expect(overlay.debugGameState.bag.entries.single.quantity, equals(1));
     });
 
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart

```diff
diff --git a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
index 92446d99..1781e72d 100644
--- a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
+++ b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
@@ -19,14 +19,19 @@ BattleStatsSnapshot _stats() {
 BattleMoveData _move({
   required String id,
   required String name,
+  int power = 40,
 }) {
   return BattleMoveData(
     id: id,
     name: name,
-    power: 40,
+    power: power,
     type: 'normal',
-    category: BattleMoveCategory.physical,
-    target: BattleMoveTarget.opponent,
+    category:
+        power <= 0 ? BattleMoveCategory.status : BattleMoveCategory.physical,
+    target: power <= 0 ? BattleMoveTarget.self : BattleMoveTarget.opponent,
+    accuracy: power <= 0
+        ? const BattleMoveAccuracy.alwaysHits()
+        : const BattleMoveAccuracy.percent(value: 100),
   );
 }
 
@@ -116,7 +121,8 @@ RuntimeActiveBattleContext _context({
 
 void main() {
   group('tryApplyRuntimeBattlePotionUse', () {
-    test('potion heals a damaged active target by 20 and consumes one item', () {
+    test('potion heals a damaged active target by 20 and consumes one item',
+        () {
       final result = tryApplyRuntimeBattlePotionUse(
         session: _session(
           player: _combatant(
@@ -129,7 +135,7 @@ void main() {
           enemy: _combatant(
             speciesId: 'enemy',
             lineupIndex: 0,
-            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
           ),
         ),
         gameState: _gameState(
@@ -151,6 +157,11 @@ void main() {
 
       expect(result, isNotNull);
       expect(result!.healedAmount, equals(20));
+      expect(result.updatedSession.state.currentTurn, isNotNull);
+      expect(
+        result.updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionPotionUse>(),
+      );
       expect(result.updatedSession.state.player.currentHp, equals(32));
       expect(result.updatedGameState.party.members.first.currentHp, equals(32));
       expect(
@@ -174,7 +185,7 @@ void main() {
           enemy: _combatant(
             speciesId: 'enemy',
             lineupIndex: 0,
-            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
           ),
         ),
         gameState: _gameState(
@@ -196,6 +207,7 @@ void main() {
 
       expect(result, isNotNull);
       expect(result!.healedAmount, equals(5));
+      expect(result.updatedSession.state.currentTurn, isNotNull);
       expect(result.updatedSession.state.player.currentHp, equals(40));
       expect(result.updatedGameState.party.members.first.currentHp, equals(40));
     });
@@ -218,13 +230,15 @@ void main() {
               lineupIndex: 0,
               currentHp: 35,
               maxHp: 40,
-              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+              moves: <BattleMoveData>[
+                _move(id: 'wait', name: 'Wait', power: 0)
+              ],
             ),
           ],
           enemy: _combatant(
             speciesId: 'enemy',
             lineupIndex: 0,
-            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
           ),
         ),
         gameState: _gameState(
@@ -247,6 +261,7 @@ void main() {
 
       expect(result, isNotNull);
       expect(result!.healedAmount, equals(5));
+      expect(result.updatedSession.state.currentTurn, isNotNull);
       expect(result.updatedSession.state.player.currentHp, equals(22));
       expect(
         result.updatedSession.state.playerReserve.single.currentHp,
@@ -279,7 +294,7 @@ void main() {
         enemy: _combatant(
           speciesId: 'enemy',
           lineupIndex: 0,
-          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
         ),
       );
 
@@ -320,7 +335,7 @@ void main() {
         enemy: _combatant(
           speciesId: 'enemy',
           lineupIndex: 0,
-          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
         ),
       );
 
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart

```diff
diff --git a/packages/map_runtime/test/battle_turn_presentation_test.dart b/packages/map_runtime/test/battle_turn_presentation_test.dart
index 701a24a7..81f30124 100644
--- a/packages/map_runtime/test/battle_turn_presentation_test.dart
+++ b/packages/map_runtime/test/battle_turn_presentation_test.dart
@@ -255,6 +255,110 @@ void main() {
       expect(steps.last.hpTo, equals(33));
     });
 
+    test(
+        'renders potion use as a committed turn step before the enemy response',
+        () {
+      final beforeSession = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          maxHp: 40,
+          currentHp: 12,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'sparkitten',
+          lineupIndex: 0,
+          maxHp: 50,
+          currentHp: 50,
+          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+        ),
+      );
+      const turn = BattleTurnResult(
+        playerAction: BattleActionPotionUse(
+          targetLineupIndex: 0,
+          healAmount: 20,
+        ),
+        enemyAction: BattleActionFight(
+          BattleMove(
+            id: 'scratch',
+            name: 'Scratch',
+            power: 35,
+            target: BattleMoveTarget.opponent,
+          ),
+          moveIndex: 0,
+        ),
+        executions: <BattleMoveExecution>[
+          BattleMoveExecution(
+            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
+            move: BattleMove(
+              id: 'scratch',
+              name: 'Scratch',
+              power: 35,
+              target: BattleMoveTarget.opponent,
+            ),
+            targetKind: BattleMoveExecutionTargetKind.combatant,
+            targetSlot: BattleSlotRef.active(BattleSideId.player),
+            damage: 9,
+            didHit: true,
+          ),
+        ],
+        potionEvents: <BattlePotionEvent>[
+          BattlePotionEvent(
+            side: BattleSideId.player,
+            targetLineupIndex: 0,
+            targetSpeciesId: 'sproutle',
+            hpBefore: 12,
+            hpAfter: 32,
+          ),
+        ],
+        timeline: <BattleTurnEvent>[
+          BattleTurnPotionEvent(
+            BattlePotionEvent(
+              side: BattleSideId.player,
+              targetLineupIndex: 0,
+              targetSpeciesId: 'sproutle',
+              hpBefore: 12,
+              hpAfter: 32,
+            ),
+          ),
+          BattleTurnExecutionEvent(
+            BattleMoveExecution(
+              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
+              move: BattleMove(
+                id: 'scratch',
+                name: 'Scratch',
+                power: 35,
+                target: BattleMoveTarget.opponent,
+              ),
+              targetKind: BattleMoveExecutionTargetKind.combatant,
+              targetSlot: BattleSlotRef.active(BattleSideId.player),
+              damage: 9,
+              didHit: true,
+            ),
+          ),
+        ],
+      );
+
+      final steps = buildBattleTurnPresentationSteps(
+        playerBefore: beforeSession.state.player,
+        enemyBefore: beforeSession.state.enemy,
+        turnResult: turn,
+      );
+
+      expect(steps, hasLength(3));
+      expect(steps[0].message, equals('Joueur utilise Potion sur sproutle !'));
+      expect(steps[0].animatesDamage, isFalse);
+      expect(steps[1].message, equals('sproutle récupère 20 PV.'));
+      expect(steps[1].animatesHpChange, isTrue);
+      expect(steps[1].flashTargetSide, isNull);
+      expect(steps[1].hpFrom, equals(12));
+      expect(steps[1].hpTo, equals(32));
+      expect(steps[2].message, equals('Ennemi utilise Scratch !'));
+      expect(steps[2].hpFrom, equals(32));
+      expect(steps[2].hpTo, equals(23));
+    });
+
     test('keeps status-like executions as message-only steps', () {
       final beforeSession = _session(
         player: _combatant(
```

### /Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart

```diff
diff --git a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
index 115cbc40..aede580f 100644
--- a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
+++ b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
@@ -582,8 +582,10 @@ void main() {
       final overlay = game.debugBattleOverlayComponent;
       expect(overlay, isNotNull);
       expect(game.debugBattleSessionSnapshot, isNotNull);
-      final initialBattleHp = game.debugBattleSessionSnapshot!.state.player.currentHp;
-      final initialBattleMaxHp = game.debugBattleSessionSnapshot!.state.player.maxHp;
+      final initialBattleHp =
+          game.debugBattleSessionSnapshot!.state.player.currentHp;
+      final initialBattleMaxHp =
+          game.debugBattleSessionSnapshot!.state.player.maxHp;
       final expectedHealedHp = min(initialBattleHp + 20, initialBattleMaxHp);
 
       overlay!.moveSelectionRight();
@@ -596,8 +598,22 @@ void main() {
 
       expect(game.debugFlowPhaseName, equals('battle'));
       expect(game.debugBattleSessionSnapshot, isNotNull);
-      expect(game.debugBattleSessionSnapshot!.state.player.currentHp, equals(expectedHealedHp));
-      expect(game.gameStateSnapshot.party.members.first.currentHp, equals(expectedHealedHp));
+      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
+      expect(currentTurn, isNotNull);
+      expect(
+        currentTurn!.playerAction,
+        isA<BattleActionPotionUse>(),
+      );
+      expect(currentTurn.potionEvents, hasLength(1));
+      expect(currentTurn.potionEvents.single.hpAfter, equals(expectedHealedHp));
+      expect(
+        game.debugBattleSessionSnapshot!.state.player.currentHp,
+        lessThanOrEqualTo(expectedHealedHp),
+      );
+      expect(
+        game.gameStateSnapshot.party.members.first.currentHp,
+        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
+      );
       expect(game.gameStateSnapshot.bag.entries, isEmpty);
     });
   });
```
