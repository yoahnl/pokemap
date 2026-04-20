# Lot 7 — Battle Pokémon Menu End-to-End Report

## 1. Résumé exécutif honnête

Le lot 7 est réussi dans le périmètre demandé. Le menu `POKÉMON` battle existe maintenant de bout en bout côté `map_runtime` :

- il s’ouvre depuis le root menu quand un switch existe ;
- il consomme le contrat pur du lot 7a ;
- il affiche actif + réserves, y compris les entrées grisées ;
- il applique un vrai `PlayerBattleChoiceSwitch(reserveIndex)` sans confondre `visualIndex` et `reserveIndex` ;
- il ouvre automatiquement sur le sous-menu en cas de `forcedReplacement` et interdit le retour arrière dans ce cas ;
- il ne touche pas à `map_battle`.

Le rendu reste volontairement minimal et textuel. Aucun écran résumé Pokémon, aucun inventaire, aucun nouveau système d’équipe parallèle n’ont été ouverts.

## 2. État git initial

Pré-gates réellement exécutés avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats initiaux :

### `git status --short --untracked-files=all`

```text
?? examples/.DS_Store
```

### `git diff --stat`

```text
<aucune différence suivie>
```

### `git ls-files --others --exclude-standard`

```text
examples/.DS_Store
```

Conclusion :
- le worktree était propre côté fichiers suivis ;
- un seul untracked hors scope existait déjà : `examples/.DS_Store`.

## 3. Fichiers lus

Reports :
- `reports/lot-7a-battle-party-switch-contract-report.md`

Runtime :
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/test/battle_party_menu_model_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_layout.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_hud_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_scene_combatant_component.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Battle :
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`

Skills relus :
- `Superpowers:brainstorming`
- `Superpowers:test-driven-development`
- `Game Studio:game-ui-frontend`

## 4. Fichiers modifiés

Modifiés :
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

Créé :
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`

## 5. Fichiers volontairement non touchés

Volontairement non touchés :
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/test/battle_party_menu_model_test.dart`
- tout `packages/map_battle/**`
- tout `packages/map_core/**`
- tout `packages/map_editor/**`
- tout `packages/map_gameplay/**`
- tout `examples/playable_runtime_host/**`

Justification :
- le contrat 7a existait déjà et suffisait ;
- le moteur battle exposait déjà `PlayerBattleChoiceSwitch(reserveIndex)` et les requests typées nécessaires ;
- le lot devait rester battle-local côté runtime/UI.

## 6. Découpage réel 7b / 7c / 7d

### 7b — rendu du sous-menu `POKÉMON`

Implémenté dans `battle_command_panel_component.dart`.

Le panel sait maintenant :
- recevoir un `BattlePartyMenuModel` ;
- afficher les entrées `allEntries` du modèle 7a ;
- rendre l’actif, les réserves K.O. et les réserves indisponibles sans les masquer ;
- afficher des labels courts de statut : `Actif`, `K.O.`, `Indisponible`, `OK`.

Le rendu reste volontairement sobre :
- nom ;
- niveau ;
- HP courant / max ;
- statut court.

### 7c — navigation et sélection

Implémenté dans `battle_overlay_component.dart`.

Comportement obtenu :
- root menu inchangé pour `FIGHT / BAG / POKÉMON / RUN` ;
- `POKÉMON` ouvre le sous-menu party sur un tour libre ;
- le focus party se positionne sur la première entrée sélectionnable ;
- navigation party en liste verticale ;
- validation seulement si `entry.playerChoice != null` ;
- escape revient au root seulement en `voluntarySwitch`.

### 7d — application réelle du switch

Implémenté dans `battle_overlay_component.dart`, sans chemin parallèle.

Le flux réel est :
1. le sous-menu choisit une `BattlePartyMenuEntry` ;
2. l’overlay lit `entry.playerChoice` ;
3. il relaye ce vrai `PlayerBattleChoiceSwitch(reserveIndex)` au callback battle existant ;
4. `updateState(...)` rafraîchit HUD et sprite joueur après résolution.

## 7. Comportement exact obtenu

### Tour libre avec switches légaux

- le root garde les 4 entrées ;
- `POKÉMON` est enabled si la request contient des `PlayerBattleChoiceSwitch` ;
- valider `POKÉMON` ouvre le sous-menu party ;
- l’actif est visible mais grisé ;
- les réserves K.O. restent visibles mais grisées ;
- les réserves valides restent sélectionnables ;
- la validation applique le vrai `PlayerBattleChoiceSwitch(reserveIndex)` porté par l’entrée.

### Remplacement forcé

- le sous-menu `POKÉMON` s’ouvre automatiquement ;
- le prompt devient `Choisis un remplaçant.` ;
- l’actif K.O. reste visible mais non sélectionnable ;
- les réserves K.O. restent visibles mais grisées ;
- le retour arrière est neutralisé ;
- aucune action `FIGHT`, `BAG` ou `RUN` n’est exécutable par retour au root.

### Index

Le lot préserve explicitement :
- `visualIndex` pour l’ordre affiché ;
- `reserveIndex` pour l’action moteur ;
- aucune entrée n’invente un switch à partir de l’ordre d’affichage.

## 8. Tests ajoutés et ce qu’ils prouvent

Ajoutés dans `packages/map_runtime/test/battle_command_menu_component_test.dart` :

1. `battle party submenu opens from root POKÉMON when switch choices exist`
- prouve l’ouverture depuis le root ;
- prouve l’affichage de l’actif et de la réserve ;
- prouve la sélection initiale sur la première réserve valide.

2. `battle party submenu keeps fainted reserves visible but disabled`
- prouve qu’une réserve K.O. reste visible ;
- prouve que `POKÉMON` reste disabled au root quand aucun switch légal n’existe réellement.

3. `party submenu preserves battle reserveIndex instead of visualIndex`
- prouve le cas anti-confusion d’index ;
- prouve qu’une entrée visuelle `2` peut produire `PlayerBattleChoiceSwitch(1)`.

4. `party submenu layout survives portrait and landscape`
- prouve l’absence de crash en `390x844` et `844x390` ;
- prouve que le sous-menu party s’ouvre dans les deux contextes.

Ajoutés / adaptés dans `packages/map_runtime/test/battle_overlay_component_test.dart` :

5. `updateState refreshes the visible prompt and command menu source`
- maintenant adapté au comportement final :
- prouve qu’un `forcedReplacement` ouvre directement le menu `POKÉMON`.

6. `voluntary switch selection applies PlayerBattleChoiceSwitch and refreshes battle state`
- prouve qu’un vrai switch joueur est relayé ;
- prouve que le HUD et le sprite joueur reflètent le nouveau Pokémon actif.

7. `forced replacement opens party menu and does not allow backing out to invalid root actions`
- prouve que le retour arrière est bloqué ;
- prouve qu’un remplacement forcé valide reste jouable ;
- prouve que le `reserveIndex` reste exact avec une réserve précédente K.O.

8. `forced replacement keeps a later valid reserve selectable after moving the cursor`
- prouve que le curseur ne snap plus en boucle vers le premier slot valide ;
- prouve qu’une deuxième réserve valide peut être choisie en forced replacement.

## 9. Validations exécutées avec résultats

Analyse ciblée réellement exécutée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/battle_party_menu_model.dart \
  lib/src/presentation/flame/battle_command_menu_model.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/battle_party_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart
```

Résultat :
- vert

Tests ciblés réellement exécutés :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_command_menu_component_test.dart
flutter test test/battle_overlay_component_test.dart
flutter test \
  test/battle_party_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :
- tout vert

`map_battle` n’a pas été touché, donc aucune validation `map_battle` n’a été relancée.

## 10. Limites restantes

Limites assumées du lot :
- pas d’écran résumé Pokémon détaillé ;
- pas de sprites miniatures dans la liste party ;
- pas de réordonnancement d’équipe ;
- pas d’objets ;
- pas de navigation 2D riche dans la liste party : le sous-menu fonctionne en liste verticale, ce qui est suffisant pour ce lot ;
- pas de pixel-perfect dédié au party menu au-delà d’un rendu lisible et responsive.

## 11. Retour des sub-agents / review séparée

Explorer sidecar utilisé :
- un explorer a confirmé le bon point d’injection dans `battle_overlay_component.dart`, autour du couple `buildBattleCommandMenuModel()` / `_handleRootActionSelected()`.

Review séparée :
- un reviewer séparé a été lancé sur les 4 fichiers modifiés ;
- il a remonté un finding réel sur le forced replacement :
  - le curseur était renvoyé au premier slot valide à chaque resync du panel ;
  - conséquence : impossible de choisir une réserve valide plus basse dans la liste ;
- le bug a été corrigé en ne snapant vers la première entrée sélectionnable qu’à l’entrée initiale dans le forced replacement ;
- un test dédié a été ajouté pour verrouiller cette non-régression.

## 12. Regard critique sur le prompt

Parties utiles :
- le découpage 7b / 7c / 7d a été très utile pour garder la séparation entre rendu, navigation et application réelle ;
- l’exigence explicite sur `reserveIndex` vs `visualIndex` était la bonne frontière de vérité ;
- l’interdiction de rouvrir `map_battle` a aidé à rester sur le seam 7a.

Parties discutables :
- l’instruction “forced replacement sans contourner le root” pouvait être lue de deux façons :
  - garder le root visible avec seulement `POKÉMON` enabled ;
  - ou auto-ouvrir le sous-menu party.
- j’ai retenu l’auto-ouverture en forced replacement, car c’est plus honnête côté UX et colle mieux au test produit “ne pas permettre de revenir à des actions invalides”.

## 13. Autocritique finale

Ce lot reste sain, mais il n’est pas parfait :
- j’ai intégré le rendu party dans `battle_command_panel_component.dart` plutôt que de créer un composant dédié ; c’est le meilleur compromis blast radius / lisibilité pour ce lot, mais ce fichier grossit ;
- le rendu textuel est fonctionnel et testable, sans encore être une UI “résumé Pokémon” premium ;
- la navigation party est volontairement simple.

En revanche, les points critiques du lot sont bien fermés :
- vérité moteur ;
- switch réel ;
- forced replacement non contournable ;
- conservation du vrai `reserveIndex`.

## 14. État git final

L’état git final exact a été relu après implémentation.

Fichiers suivis modifiés :
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

Nouveaux fichiers non suivis :
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`

Untracked préexistant hors scope toujours présent :
- `examples/.DS_Store`

Diff stat final relu :

```text
 .../flame/battle_command_panel_component.dart      | 341 ++++++++++++++++++++-
 .../flame/battle_overlay_component.dart            | 155 +++++++++-
 .../test/battle_command_menu_component_test.dart   | 203 ++++++++++++
 .../test/battle_overlay_component_test.dart        | 168 +++++++++-
 4 files changed, 858 insertions(+), 9 deletions(-)
```

## 15. Décision finale

**Lot 7 réussi — le menu `POKÉMON` battle fonctionne maintenant de bout en bout côté runtime, consomme le contrat pur 7a, applique de vrais switches joueur avec les bons `reserveIndex`, ferme le remplacement forcé sans contourner le moteur, et prépare proprement les éventuels raffinements UX futurs sans rouvrir `map_battle`.**
