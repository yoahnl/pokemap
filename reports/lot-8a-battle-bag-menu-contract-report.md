# Lot 8a — Battle Bag Menu Contract Report

## 1. Résumé exécutif honnête

Le lot 8a est réussi dans le périmètre demandé.

Un contrat pur, testable, a été ajouté côté `map_runtime` pour représenter le futur menu `BAG` en combat :

- il lit le vrai `GameState.bag` ;
- il normalise les entrées via `Bag.normalized()` ;
- il expose les entrées visibles, leur quantité, leur classification et leur état sélectionnable ou grisé ;
- il n’expose une vraie action capture que si `BattleSession.decisionRequest` autorise déjà réellement `PlayerBattleChoiceCapture` ;
- il ne consomme rien, ne soigne rien, n’applique rien, et ne touche pas à `map_battle`.

Le lot ne rend pas encore le sac, n’ouvre pas encore le sous-menu `BAG`, et ne change pas l’overlay.

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

- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`

Runtime :

- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/test/battle_party_menu_model_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Battle :

- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_setup.dart`

Core :

- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`

Skills relus :

- `Superpowers:brainstorming`
- `Superpowers:test-driven-development`

`Game Studio` a été explicitement écarté pour ce lot, car il ne s’agit ni d’un rendu UI, ni d’un travail de front de jeu, mais d’un contrat pur de modèle.

## 4. Fichiers modifiés/créés

Créés :

- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `reports/lot-8a-battle-bag-menu-contract-report.md`

## 5. Fichiers volontairement non touchés

Volontairement non touchés :

- tout `packages/map_battle/**`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- tout `examples/playable_runtime_host/**`
- tout `packages/map_editor/**`
- tout `packages/map_core/**`

Justification :

- le lot 8a devait rester un contrat pur côté `map_runtime` ;
- aucune UI `BAG` ne devait être ouverte ;
- aucune action d’objet ne devait être créée côté moteur ;
- le bag persistant et la capture existent déjà assez pour projeter un modèle sans modifier les packages source.

## 6. Description du contrat créé

Le nouveau contrat vit dans :

- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`

Surface créée :

- `BattleBagMenuMode`
- `BattleBagItemKind`
- `BattleBagMenuDisabledReason`
- `BattleBagMenuAction`
- `BattleBagMenuActionCapture`
- `BattleBagMenuEntry`
- `BattleBagMenuModel`
- `buildBattleBagMenuModel({ required GameState gameState, required BattleSession session })`

Propriétés principales :

- le modèle lit `gameState.bag.normalized()` ;
- chaque entrée expose :
  - `visualIndex`
  - `itemId`
  - `categoryId`
  - `quantity`
  - `kind`
  - `isSelectable`
  - `disabledReason`
  - `action`
- le modèle expose :
  - `entries`
  - `mode`
  - `hasEntries`
  - `hasSelectableEntries`

Modes retenus :

- `empty`
- `available`
- `unavailable`

Classification retenue :

- `poke-ball` dans `items` => `captureBall`
- `medicine` => `medicine`
- tout le reste => `unsupported`

Invariants respectés :

- aucune consommation d’objet ;
- aucune modification de `GameState` ;
- aucun appel à `session.applyChoice(...)` ;
- aucun appel à `applyRuntimeBattleOutcomeToGameState(...)` ;
- aucune synthèse d’une action capture si la request ne l’autorise pas déjà.

## 7. Comportement Poké Ball

Le contrat capture suit une règle stricte :

- si la request courante expose déjà un vrai `PlayerBattleChoiceCapture`, l’entrée `poke-ball` devient sélectionnable ;
- son `action` est alors un `BattleBagMenuActionCapture` portant exactement ce `PlayerBattleChoiceCapture` ;
- sinon, l’entrée reste visible mais grisée.

Raisons de désactivation actuellement exposées pour une Poké Ball :

- `trainerBattle`
- `partyFull`
- `captureUnavailable`
- `currentRequestDisallowsBag`

Politique retenue :

- trainer battle => Poké Ball visible mais grisée ;
- forced replacement => Poké Ball visible mais grisée ;
- continue / wait => Poké Ball visible mais grisée ;
- wild battle non trainer avec capture absente de la request => aucune action synthétique ;
- si la party est pleine et que `allowCapture` n’est pas autorisé, la raison affichée est `partyFull`.

Le contrat reste honnête :

- la vérité d’action vient toujours de `session.decisionRequest.allowedChoices` ;
- `GameState` et `session.setup` servent seulement à améliorer la raison de désactivation, pas à inventer une action.

## 8. Comportement medicine / unsupported

Les items `medicine` :

- restent visibles ;
- sont classés `BattleBagItemKind.medicine` ;
- restent non sélectionnables ;
- portent la raison `medicineNotImplemented`.

Les items inconnus / non supportés :

- restent visibles ;
- sont classés `BattleBagItemKind.unsupported` ;
- restent non sélectionnables ;
- portent la raison `unsupportedItem`.

Aucune action d’objet générique n’a été ouverte.

## 9. Tests ajoutés et ce qu’ils prouvent

Ajoutés dans :

- `packages/map_runtime/test/battle_bag_menu_model_test.dart`

Tests ajoutés :

1. `empty bag builds a non-actionable empty model`
- prouve qu’un sac vide ne crash pas ;
- prouve `entries.isEmpty` ;
- prouve `mode == empty` ;
- prouve `hasEntries == false` et `hasSelectableEntries == false`.

2. `wild battle with poke-ball and allowed capture exposes a selectable capture entry`
- prouve qu’une Poké Ball devient sélectionnable uniquement si la capture est déjà autorisée ;
- prouve la quantité ;
- prouve la classification `captureBall` ;
- prouve que l’action expose un vrai `PlayerBattleChoiceCapture`.

3. `trainer battle keeps poke-ball visible but disabled`
- prouve qu’une Poké Ball ne disparaît pas en trainer battle ;
- prouve qu’elle reste non sélectionnable ;
- prouve une raison de désactivation explicite.

4. `wild battle with poke-ball but full party keeps capture disabled with an explicit reason`
- prouve le cas party pleine ;
- prouve qu’aucune action n’est exposée ;
- prouve une raison plus honnête que juste “unavailable”.

5. `forced replacement keeps bag visible but non-actionable`
- prouve qu’un état de remplacement forcé ne synthétise pas de capture ;
- prouve une raison liée à la request courante.

6. `continue request never exposes a fake capture action`
- prouve qu’une request non libre ne crée pas de faux `PlayerBattleChoiceCapture`.

7. `medicine stays visible with a non-implemented disabled reason`
- prouve que les objets medicine apparaissent déjà dans le contrat ;
- prouve qu’ils restent grisés et non implémentés.

8. `unknown items stay visible but unsupported`
- prouve que les objets inconnus restent visibles ;
- prouve qu’ils ne deviennent jamais actionnables.

9. `duplicate bag entries are merged through Bag.normalized()`
- prouve que le modèle consomme bien la version normalisée du bag ;
- prouve la fusion des doublons compatibles ;
- prouve un ordre stable issu de `Bag.normalized()`.

10. `capture action is never synthesized when the current request does not allow it`
- prouve explicitement l’anti-synthèse ;
- même avec une Poké Ball réelle dans le bag, aucune action capture n’est créée si la request ne la porte pas déjà.

En plus, les tests de régression relancés prouvent que :

- le contrat party battle existant reste inchangé ;
- le menu battle existant reste intact ;
- l’overlay battle existant reste intact ;
- le flow wild runtime minimal reste intact.

## 10. Validations exécutées et résultats

Commandes réellement exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_bag_menu_model_test.dart
```

Résultat :

- rouge initial vérifié avant implémentation ;
- échec attendu pour absence du fichier/contrat `battle_bag_menu_model.dart`.

Puis :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub lib/src/presentation/flame/battle_bag_menu_model.dart test/battle_bag_menu_model_test.dart
```

Résultat :

- vert ;
- `No issues found!`

Puis :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_bag_menu_model_test.dart
```

Résultat :

- vert ;
- `10` tests passés.

Puis :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_party_menu_model_test.dart test/battle_command_menu_component_test.dart test/battle_overlay_component_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- vert ;
- régression runtime battle non cassée.

## 11. Limites assumées

Limites explicites de ce lot :

- aucune UI `BAG` n’est rendue ;
- le bouton `BAG` battle n’est pas branché ;
- aucune action `use item` n’est créée ;
- aucune Poké Ball n’est consommée ;
- aucune capture n’est appliquée ;
- aucun soin n’est appliqué ;
- aucune logique d’inventaire complète n’est ouverte ;
- le modèle ne connaît pas encore les noms localisés réels des items ;
- le modèle ne gère pas encore de sous-catégories visuelles de sac.

Le lot reste donc un contrat pur, prêt pour un futur lot d’UI BAG, et rien de plus.

## 12. État git final

Pré-gates rerun après création du report :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

### `git status --short --untracked-files=all`

```text
?? examples/.DS_Store
?? packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
?? packages/map_runtime/test/battle_bag_menu_model_test.dart
?? reports/lot-8a-battle-bag-menu-contract-report.md
```

### `git diff --stat`

```text
<aucune différence suivie>
```

### `git ls-files --others --exclude-standard`

```text
examples/.DS_Store
packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
packages/map_runtime/test/battle_bag_menu_model_test.dart
reports/lot-8a-battle-bag-menu-contract-report.md
```

Conclusion :

- le lot a ajouté exactement deux nouveaux fichiers runtime et un report ;
- aucun fichier suivi existant n’a été modifié ;
- l’untracked hors scope `examples/.DS_Store` est toujours présent et n’a pas été touché.

## 13. Décision finale

Lot 8a réussi.

Le menu BAG battle dispose maintenant d’un contrat pur, testable, honnête, prêt à être consommé par un futur sous-menu runtime, sans toucher au moteur battle ni ouvrir prématurément la logique d’objet.
