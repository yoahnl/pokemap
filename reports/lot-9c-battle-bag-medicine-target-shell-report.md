# Lot 9-c — Battle BAG medicine target shell

## Résumé exécutif

Le lot 9-c est implémenté dans `packages/map_runtime` uniquement.

Le BAG battle ne laisse plus `potion` dans un cul-de-sac `Not implemented` :

- `Potion` ouvre maintenant un vrai sous-menu de ciblage construit depuis la lineup battle courante ;
- les cibles vivantes et blessées sont sélectionnables ;
- les cibles `K.O.` et `Full HP` restent visibles mais désactivées ;
- sélectionner une cible valide n'applique toujours aucun soin ;
- sélectionner une cible valide ne consomme toujours pas la potion ;
- sélectionner une cible valide ne dispatch toujours aucun `PlayerBattleChoice`.

La capture BAG du lot 9-b reste inchangée.

## Continuité du chantier

Ce lot continue bien le chantier BAG runtime/UI :

- `lot-9a` : shell UI du BAG
- `lot-9b` : wiring capture depuis le BAG
- `lot-9c` : shell de ciblage medicine

Ce lot ne continue pas `BDC-01` et n'a touché ni le move bridge runtime→battle, ni `Bubble`/`Bubble Beam`, ni le converter Showdown.

## État git initial exact

Pré-gates exécutés avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
```

Résultat initial :

```text
<clean>
```

Classification initiale :

- `preexisting_in_scope`: none
- `preexisting_out_of_scope`: none
- `created_by_this_lot`: none au départ
- `modified_by_this_lot`: none au départ

## Fichiers lus

Rapports :

- `reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `reports/lot-9b-battle-bag-capture-wiring-report.md`
- `reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`
- `reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`

Runtime :

- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`

Tests :

- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/test/battle_party_menu_model_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

## Fichiers modifiés ou créés

Modifiés :

- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

Créés :

- `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart`
- `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`

## Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`

## Comportement obtenu

### BAG

- `poke-ball` garde le comportement capture du lot 9-b ;
- `potion` + `categoryId == medicine` devient sélectionnable pendant un vrai `BattleTurnChoiceRequest` ;
- les autres medicines restent visibles mais désactivées avec une raison explicite ;
- les items unsupported restent visibles mais désactivés ;
- les doublons BAG restent fusionnés via `Bag.normalized()`.

### Ciblage medicine

- le shell cible l'actif joueur puis les réserves de la lineup battle courante ;
- il n'utilise pas la party complète du `GameState` ;
- il préserve les vrais `lineupIndex` / `reserveIndex` battle ;
- une cible est sélectionnable uniquement si elle est vivante et blessée ;
- une cible `K.O.` reste visible mais désactivée ;
- une cible `Full HP` reste visible mais désactivée ;
- si aucune cible n'est valide, le shell s'ouvre quand même, sans faux message d'utilisation.

### Overlay

- sélectionner `Potion` depuis le BAG ouvre le mode local `bagMedicineTarget` ;
- le curseur se place sur la première cible valide si elle existe, sinon reste à `0` ;
- valider une cible invalide renvoie `false` ;
- valider une cible valide renvoie `true`, affiche un feedback shell, et n'envoie aucun choix battle ;
- `Escape` revient du shell medicine vers BAG, puis de BAG vers root ;
- le forced replacement ne gagne pas d'accès au BAG ni au shell medicine.

## Désaccords avec le prompt et arbitrages retenus

### 1. Je n'ai pas déplacé les prompts/narrations dans `battle_turn_presentation.dart`

Je ne suis pas d'accord avec l'idée implicite du prompt de pousser la narration shell medicine dans `battle_turn_presentation.dart`.

Raison :

- dans l'architecture actuelle, les prompts de menus interactifs BAG/POKÉMON vivent déjà dans `battle_overlay_component.dart` ;
- `battle_turn_presentation.dart` porte la transformation d'un `turnResult.timeline` en steps de présentation, pas les prompts de navigation des sous-menus ;
- déplacer la logique de prompt UI interactive là-dedans aurait mélangé deux responsabilités qui sont aujourd'hui séparées proprement.

J'ai donc ajouté les helpers `buildBattleMedicineTargetPromptForOverlay(...)` et `buildBattleMedicineTargetNarrationLinesForOverlay(...)` dans `battle_overlay_component.dart`, au même endroit que les helpers BAG et POKÉMON existants.

### 2. Je n'ai pas désactivé `Potion` au niveau BAG quand aucune cible n'est valide

Je ne suis pas d'accord avec une lecture plus stricte du prompt qui aurait conduit à ajouter un disabled reason BAG du type `noValidMedicineTarget`.

Raison :

- le prompt lui-même dit de privilégier le shell qui s'ouvre même quand aucune cible n'est valide ;
- ce comportement est meilleur UX ici, parce qu'il montre la lineup battle courante et explique honnêtement pourquoi rien n'est ciblable ;
- désactiver `Potion` en amont aurait recréé un mini cul-de-sac UI, juste plus sophistiqué.

J'ai donc gardé `Potion` sélectionnable en tour libre, puis laissé le shell medicine porter la vérité sur les cibles valides ou non.

### 3. J'ai créé un modèle dédié au lieu de réutiliser le modèle switch

Je ne suis pas d'accord avec une réutilisation trop agressive du modèle de switch party.

Raison :

- le modèle switch porte déjà une sémantique `PlayerBattleChoiceSwitch` ;
- le shell medicine n'a justement pas le droit de synthétiser un `PlayerBattleChoice` ;
- réutiliser le switch comme faux item-target aurait masqué une différence métier importante et rendu le lot 9-d plus ambigu ensuite.

J'ai donc créé `battle_medicine_target_menu_model.dart`, avec un contrat dédié, sans action battle cachée.

## Preuve qu'aucun soin ni dispatch n'est branché

- aucun changement `map_battle`
- aucun changement `BattleSession`
- aucun changement `GameState`
- aucune création de `PlayerBattleChoiceUseItem`
- aucune consommation de potion
- aucun write-back inventaire
- aucun heal amount runtime
- aucun dispatch `onPlayerChoice` depuis le shell medicine

Le feedback après validation reste explicitement non-destructif :

```text
L’utilisation de Potion sera branchée au prochain lot.
```

## Tests ajoutés ou modifiés

### `battle_bag_menu_model_test.dart`

- `supported potion is selectable in a free turn and opens a medicine target action`
- `unsupported medicine stays visible but disabled`
- `potion is non-selectable when the current request disallows bag`

### `battle_medicine_target_menu_model_test.dart`

- `lists the active pokemon then reserves in battle lineup order`
- `damaged living pokemon are selectable`
- `full hp pokemon stay visible but non-selectable`
- `fainted pokemon stay visible but non-selectable`
- `hasSelectableEntries is false when everyone is full hp or fainted`

### `battle_command_menu_component_test.dart`

- BAG submenu mis à jour pour `Potion` sélectionnable
- `battle medicine target submenu shows active and reserve pokemon`

### `battle_overlay_component_test.dart`

- `selecting potion from battle bag opens the medicine target shell without dispatching`
- `selecting a valid medicine target shows shell feedback without dispatching or mutating state`
- `full hp medicine targets stay visible but non-selectable`
- `fainted medicine targets stay visible but non-selectable`
- `escape from medicine target returns to bag and then to root`

## Validations exécutées

Depuis `packages/map_runtime` :

```bash
flutter test test/battle_bag_menu_model_test.dart
flutter test test/battle_medicine_target_menu_model_test.dart
flutter test test/battle_command_menu_component_test.dart
flutter test test/battle_overlay_component_test.dart
flutter test test/battle_bag_menu_model_test.dart test/battle_medicine_target_menu_model_test.dart test/battle_command_menu_component_test.dart test/battle_overlay_component_test.dart
flutter analyze --no-pub lib/src/presentation/flame/battle_bag_menu_model.dart lib/src/presentation/flame/battle_medicine_target_menu_model.dart lib/src/presentation/flame/battle_command_menu_model.dart lib/src/presentation/flame/battle_command_panel_component.dart lib/src/presentation/flame/battle_overlay_component.dart test/battle_bag_menu_model_test.dart test/battle_medicine_target_menu_model_test.dart test/battle_command_menu_component_test.dart test/battle_overlay_component_test.dart
flutter test
```

Résultats :

- sous-ensemble 9-c : vert
- analyze ciblé : vert
- suite `packages/map_runtime` complète : vert

## État git final exact

Pré-gates finaux exécutés :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat final :

```text
 M packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/battle_bag_menu_model_test.dart
 M packages/map_runtime/test/battle_command_menu_component_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
?? packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart
?? packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
?? reports/lot-9c-battle-bag-medicine-target-shell-report.md
```

```text
 .../presentation/flame/battle_bag_menu_model.dart  |  70 +++++-
 .../flame/battle_command_menu_model.dart           |   7 +
 .../flame/battle_command_panel_component.dart      | 244 +++++++++++++++++++++
 .../flame/battle_overlay_component.dart            | 209 +++++++++++++++++-
 .../test/battle_bag_menu_model_test.dart           | 102 ++++++++-
 .../test/battle_command_menu_component_test.dart   |  96 +++++++-
 .../test/battle_overlay_component_test.dart        | 232 +++++++++++++++++++-
 7 files changed, 932 insertions(+), 28 deletions(-)
```

```text
packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart
packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
reports/lot-9c-battle-bag-medicine-target-shell-report.md
```

Classification finale :

- `preexisting_in_scope`: none
- `preexisting_out_of_scope`: none
- `created_by_this_lot`:
  - `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart`
  - `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`
  - `reports/lot-9c-battle-bag-medicine-target-shell-report.md`
- `modified_by_this_lot`:
  - `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - `packages/map_runtime/test/battle_bag_menu_model_test.dart`
  - `packages/map_runtime/test/battle_command_menu_component_test.dart`
  - `packages/map_runtime/test/battle_overlay_component_test.dart`

## Limites explicitement conservées

- `Potion` ne soigne pas encore
- `Potion` n'est pas consommée
- aucune medicine autre que `potion` n'est supportée
- pas de revive
- pas de status heal
- pas de battle items
- pas de write-back post-combat pour medicine
- pas de changement de capture BAG

## Annexe code — nouveaux fichiers complets

### `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart`

```dart
import 'package:map_battle/map_battle.dart';

enum BattleMedicineTargetDisabledReason {
  fainted,
  fullHp,
  notAllowedByCurrentRequest,
}

class BattleMedicineTargetEntry {
  const BattleMedicineTargetEntry({
    required this.visualIndex,
    required this.lineupIndex,
    required this.reserveIndex,
    required this.speciesId,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.isActive,
    required this.isFainted,
    required this.isSelectable,
    required this.disabledReason,
  });

  final int visualIndex;
  final int lineupIndex;
  final int? reserveIndex;
  final String speciesId;
  final int level;
  final int currentHp;
  final int maxHp;
  final bool isActive;
  final bool isFainted;
  final bool isSelectable;
  final BattleMedicineTargetDisabledReason? disabledReason;
}

class BattleMedicineTargetMenuModel {
  const BattleMedicineTargetMenuModel({
    required this.itemId,
    required this.categoryId,
    required this.activeEntry,
    required this.reserveEntries,
    required this.entries,
  });

  final String itemId;
  final String categoryId;
  final BattleMedicineTargetEntry activeEntry;
  final List<BattleMedicineTargetEntry> reserveEntries;
  final List<BattleMedicineTargetEntry> entries;

  bool get hasSelectableEntries => entries.any((entry) => entry.isSelectable);
}

BattleMedicineTargetMenuModel buildBattleMedicineTargetMenuModel({
  required BattleSession session,
  required String itemId,
  required String categoryId,
}) {
  final allowsTargeting = session.decisionRequest is BattleTurnChoiceRequest;

  BattleMedicineTargetEntry buildEntry({
    required int visualIndex,
    required int? reserveIndex,
    required BattleCombatant combatant,
    required bool isActive,
  }) {
    final isFainted = combatant.isFainted;
    final isFullHp = combatant.currentHp >= combatant.maxHp;
    final isSelectable = allowsTargeting && !isFainted && !isFullHp;
    final disabledReason = isSelectable
        ? null
        : !allowsTargeting
            ? BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest
            : isFainted
                ? BattleMedicineTargetDisabledReason.fainted
                : BattleMedicineTargetDisabledReason.fullHp;

    return BattleMedicineTargetEntry(
      visualIndex: visualIndex,
      lineupIndex: combatant.lineupIndex,
      reserveIndex: reserveIndex,
      speciesId: combatant.speciesId,
      level: combatant.level,
      currentHp: combatant.currentHp,
      maxHp: combatant.maxHp,
      isActive: isActive,
      isFainted: isFainted,
      isSelectable: isSelectable,
      disabledReason: disabledReason,
    );
  }

  final activeEntry = buildEntry(
    visualIndex: 0,
    reserveIndex: null,
    combatant: session.state.player,
    isActive: true,
  );

  final reserveEntries = <BattleMedicineTargetEntry>[
    for (var index = 0; index < session.state.playerReserve.length; index++)
      buildEntry(
        visualIndex: index + 1,
        reserveIndex: index,
        combatant: session.state.playerReserve[index],
        isActive: false,
      ),
  ];

  return BattleMedicineTargetMenuModel(
    itemId: itemId,
    categoryId: categoryId,
    activeEntry: activeEntry,
    reserveEntries: List<BattleMedicineTargetEntry>.unmodifiable(
      reserveEntries,
    ),
    entries: List<BattleMedicineTargetEntry>.unmodifiable(
      <BattleMedicineTargetEntry>[activeEntry, ...reserveEntries],
    ),
  );
}
```

### `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_medicine_target_menu_model.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: 40,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int level = 30,
  int maxHp = 40,
  int? currentHp,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
}

void main() {
  group('BattleMedicineTargetMenuModel', () {
    test('lists the active pokemon then reserves in battle lineup order', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 4,
            currentHp: 25,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'bench_one',
              lineupIndex: 7,
              currentHp: 10,
              maxHp: 35,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
            _combatant(
              speciesId: 'bench_two',
              lineupIndex: 9,
              currentHp: 35,
              maxHp: 35,
              moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.itemId, equals('potion'));
      expect(model.categoryId, equals('medicine'));
      expect(model.entries.map((entry) => entry.speciesId), const <String>[
        'sproutle',
        'bench_one',
        'bench_two',
      ]);
      expect(model.entries.map((entry) => entry.visualIndex), const <int>[
        0,
        1,
        2,
      ]);
      expect(model.entries.map((entry) => entry.lineupIndex), const <int>[
        4,
        7,
        9,
      ]);
      expect(model.entries.map((entry) => entry.reserveIndex), const <int?>[
        null,
        0,
        1,
      ]);
    });

    test('damaged living pokemon are selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 15,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.activeEntry.disabledReason, isNull);
      expect(model.hasSelectableEntries, isTrue);
    });

    test('full hp pokemon stay visible but non-selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.activeEntry.isSelectable, isFalse);
      expect(
        model.activeEntry.disabledReason,
        equals(BattleMedicineTargetDisabledReason.fullHp),
      );
    });

    test('fainted pokemon stay visible but non-selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 20,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 2,
              currentHp: 0,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattleMedicineTargetDisabledReason.fainted),
      );
    });

    test('hasSelectableEntries is false when everyone is full hp or fainted',
        () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'full_bench',
              lineupIndex: 1,
              currentHp: 30,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 2,
              currentHp: 0,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.hasSelectableEntries, isFalse);
      expect(
        model.entries.map((entry) => entry.isSelectable),
        const <bool>[false, false, false],
      );
    });
  });
}
```

## Annexe code — diffs exacts des fichiers modifiés

### `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
index 5c739767..16138b7c 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
@@ -19,6 +19,7 @@ enum BattleBagMenuDisabledReason {
   captureUnavailable,
   currentRequestDisallowsBag,
   medicineNotImplemented,
+  unsupportedMedicine,
   unsupportedItem,
 }
 
@@ -32,6 +33,18 @@ final class BattleBagMenuActionCapture extends BattleBagMenuAction {
   final PlayerBattleChoiceCapture playerChoice;
 }
 
+final class BattleBagMenuActionMedicineTarget extends BattleBagMenuAction {
+  const BattleBagMenuActionMedicineTarget({
+    required this.itemId,
+    required this.categoryId,
+    required this.quantity,
+  });
+
+  final String itemId;
+  final String categoryId;
+  final int quantity;
+}
+
 class BattleBagMenuEntry {
   const BattleBagMenuEntry({
     required this.visualIndex,
@@ -65,8 +78,7 @@ class BattleBagMenuModel {
 
   bool get hasEntries => entries.isNotEmpty;
 
-  bool get hasSelectableEntries =>
-      entries.any((entry) => entry.isSelectable);
+  bool get hasSelectableEntries => entries.any((entry) => entry.isSelectable);
 }
 
 BattleBagMenuModel buildBattleBagMenuModel({
@@ -120,15 +132,10 @@ BattleBagMenuEntry _buildEntry({
         session: session,
         captureChoice: captureChoice,
       ),
-    BattleBagItemKind.medicine => BattleBagMenuEntry(
+    BattleBagItemKind.medicine => _buildMedicineEntry(
         visualIndex: visualIndex,
-        itemId: bagEntry.itemId,
-        categoryId: bagEntry.categoryId,
-        quantity: bagEntry.quantity,
-        kind: kind,
-        isSelectable: false,
-        disabledReason: BattleBagMenuDisabledReason.medicineNotImplemented,
-        action: null,
+        bagEntry: bagEntry,
+        session: session,
       ),
     BattleBagItemKind.unsupported => BattleBagMenuEntry(
         visualIndex: visualIndex,
@@ -168,6 +175,45 @@ BattleBagMenuEntry _buildCaptureEntry({
   );
 }
 
+BattleBagMenuEntry _buildMedicineEntry({
+  required int visualIndex,
+  required BagEntry bagEntry,
+  required BattleSession session,
+}) {
+  if (!_isSupportedMedicine(bagEntry)) {
+    return BattleBagMenuEntry(
+      visualIndex: visualIndex,
+      itemId: bagEntry.itemId,
+      categoryId: bagEntry.categoryId,
+      quantity: bagEntry.quantity,
+      kind: BattleBagItemKind.medicine,
+      isSelectable: false,
+      disabledReason: BattleBagMenuDisabledReason.unsupportedMedicine,
+      action: null,
+    );
+  }
+
+  final bagAllowed = session.decisionRequest is BattleTurnChoiceRequest;
+  return BattleBagMenuEntry(
+    visualIndex: visualIndex,
+    itemId: bagEntry.itemId,
+    categoryId: bagEntry.categoryId,
+    quantity: bagEntry.quantity,
+    kind: BattleBagItemKind.medicine,
+    isSelectable: bagAllowed,
+    disabledReason: bagAllowed
+        ? null
+        : BattleBagMenuDisabledReason.currentRequestDisallowsBag,
+    action: bagAllowed
+        ? BattleBagMenuActionMedicineTarget(
+            itemId: bagEntry.itemId,
+            categoryId: bagEntry.categoryId,
+            quantity: bagEntry.quantity,
+          )
+        : null,
+  );
+}
+
 PlayerBattleChoiceCapture? _captureChoiceFor(BattleDecisionRequest request) {
   for (final choice in request.allowedChoices) {
     if (choice is PlayerBattleChoiceCapture) {
@@ -187,6 +233,10 @@ BattleBagItemKind _classifyBagItem(BagEntry bagEntry) {
   return BattleBagItemKind.unsupported;
 }
 
+bool _isSupportedMedicine(BagEntry bagEntry) {
+  return bagEntry.itemId == 'potion' && bagEntry.categoryId == 'medicine';
+}
+
 BattleBagMenuDisabledReason _captureDisabledReason({
   required GameState gameState,
   required BattleSession session,
```

### `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart b/packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
index d8a708e6..31cc81db 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
@@ -12,6 +12,7 @@ enum BattleCommandMenuMode {
   root,
   fight,
   bag,
+  bagMedicineTarget,
   pokemon,
   continueOnly,
 }
@@ -88,6 +89,7 @@ BattleCommandMenuMode normalizeBattleCommandMenuMode({
     case BattleCommandMenuMode.root:
     case BattleCommandMenuMode.fight:
     case BattleCommandMenuMode.bag:
+    case BattleCommandMenuMode.bagMedicineTarget:
     case BattleCommandMenuMode.pokemon:
       return currentMode;
     case BattleCommandMenuMode.continueOnly:
@@ -207,6 +209,10 @@ BattleCommandMenuMode _normalizeSubmenuAgainstRequest({
       request is! BattleTurnChoiceRequest) {
     return BattleCommandMenuMode.root;
   }
+  if (mode == BattleCommandMenuMode.bagMedicineTarget &&
+      request is! BattleTurnChoiceRequest) {
+    return BattleCommandMenuMode.root;
+  }
   return mode;
 }
 
@@ -303,6 +309,7 @@ String _choiceGroupTitleFor(BattleCommandMenuMode mode) {
     BattleCommandMenuMode.root => 'COMMANDS',
     BattleCommandMenuMode.fight => 'MOVES',
     BattleCommandMenuMode.bag => 'BAG',
+    BattleCommandMenuMode.bagMedicineTarget => 'TARGET',
     BattleCommandMenuMode.pokemon => 'POKÉMON',
     BattleCommandMenuMode.continueOnly => 'CONTINUE',
   };
```

### `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
index 05d0a22d..a5e815a1 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
@@ -8,6 +8,7 @@ import 'package:map_battle/map_battle.dart';
 
 import 'battle_bag_menu_model.dart';
 import 'battle_command_menu_model.dart';
+import 'battle_medicine_target_menu_model.dart';
 import 'battle_party_menu_model.dart';
 import 'battle_scene_layout.dart';
 
@@ -81,6 +82,7 @@ class BattleCommandPanelComponent extends PositionComponent {
     required this.onRootActionSelected,
     required this.onPartyEntrySelected,
     this.onBagEntrySelected,
+    this.onMedicineTargetEntrySelected,
     this.layoutModeOverride,
   }) : super(
           position: position,
@@ -93,6 +95,8 @@ class BattleCommandPanelComponent extends PositionComponent {
   final void Function(BattleCommandRootAction action) onRootActionSelected;
   final void Function(BattlePartyMenuEntry entry) onPartyEntrySelected;
   final void Function(BattleBagMenuEntry entry)? onBagEntrySelected;
+  final void Function(BattleMedicineTargetEntry entry)?
+      onMedicineTargetEntrySelected;
   final BattleCommandPanelLayoutMode? layoutModeOverride;
 
   PositionComponent? _promptPanel;
@@ -114,8 +118,10 @@ class BattleCommandPanelComponent extends PositionComponent {
   _BattleCommandPanelLayout? _layout;
   BattlePartyMenuModel? _partyMenuModel;
   BattleBagMenuModel? _bagMenuModel;
+  BattleMedicineTargetMenuModel? _medicineTargetMenuModel;
   int _selectedPartyIndex = 0;
   int _selectedBagIndex = 0;
+  int _selectedMedicineTargetIndex = 0;
   BattleCommandMenuModel _menuModel = const BattleCommandMenuModel(
     mode: BattleCommandMenuMode.root,
     rootEntries: <BattleCommandRootEntry>[],
@@ -207,6 +213,27 @@ class BattleCommandPanelComponent extends PositionComponent {
   @visibleForTesting
   int get currentSelectedBagIndex => _selectedBagIndex;
 
+  @visibleForTesting
+  List<String> get currentMedicineTargetSpeciesLabels =>
+      (_medicineTargetMenuModel?.entries ?? const <BattleMedicineTargetEntry>[])
+          .map((entry) => entry.speciesId)
+          .toList(growable: false);
+
+  @visibleForTesting
+  List<bool> get currentMedicineTargetSelectableStates =>
+      (_medicineTargetMenuModel?.entries ?? const <BattleMedicineTargetEntry>[])
+          .map((entry) => entry.isSelectable)
+          .toList(growable: false);
+
+  @visibleForTesting
+  List<String> get currentMedicineTargetStatusLabels =>
+      (_medicineTargetMenuModel?.entries ?? const <BattleMedicineTargetEntry>[])
+          .map(_medicineTargetStatusLabel)
+          .toList(growable: false);
+
+  @visibleForTesting
+  int get currentSelectedMedicineTargetIndex => _selectedMedicineTargetIndex;
+
   @visibleForTesting
   BattleCommandPanelLayoutMode get currentLayoutMode =>
       _layout?.mode ?? BattleCommandPanelLayoutMode.split;
@@ -334,16 +361,20 @@ class BattleCommandPanelComponent extends PositionComponent {
     required BattleCommandMenuModel menuModel,
     BattlePartyMenuModel? partyMenuModel,
     BattleBagMenuModel? bagMenuModel,
+    BattleMedicineTargetMenuModel? medicineTargetMenuModel,
     int selectedPartyIndex = 0,
     int selectedBagIndex = 0,
+    int selectedMedicineTargetIndex = 0,
     bool allowEmptyNarrationBody = false,
     bool interactionsEnabled = true,
   }) {
     _menuModel = menuModel;
     _partyMenuModel = partyMenuModel;
     _bagMenuModel = bagMenuModel;
+    _medicineTargetMenuModel = medicineTargetMenuModel;
     _selectedPartyIndex = selectedPartyIndex;
     _selectedBagIndex = selectedBagIndex;
+    _selectedMedicineTargetIndex = selectedMedicineTargetIndex;
     _battleLabelText?.text = battleLabel.toUpperCase();
     _currentPromptValue = prompt;
     _promptText?.text = prompt;
@@ -463,6 +494,15 @@ class BattleCommandPanelComponent extends PositionComponent {
       return;
     }
 
+    if (_menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
+        _medicineTargetMenuModel != null) {
+      _renderMedicineTargetEntries(
+        commandsPanel,
+        interactionsEnabled: interactionsEnabled,
+      );
+      return;
+    }
+
     if (_menuModel.isContinueOnly) {
       _renderChoiceEntries(
         commandsPanel,
@@ -681,6 +721,60 @@ class BattleCommandPanelComponent extends PositionComponent {
     }
   }
 
+  void _renderMedicineTargetEntries(
+    PositionComponent commandsPanel, {
+    required bool interactionsEnabled,
+  }) {
+    final medicineTargetMenuModel = _medicineTargetMenuModel;
+    if (medicineTargetMenuModel == null) {
+      return;
+    }
+
+    final layout = _layout ?? _BattleCommandPanelLayout.forSize(size);
+    final top =
+        layout.mode == BattleCommandPanelLayoutMode.stacked ? 18.0 : 24.0;
+    final gap = layout.mode == BattleCommandPanelLayoutMode.stacked ? 7.0 : 8.0;
+    final entries = medicineTargetMenuModel.entries;
+    if (entries.isEmpty) {
+      return;
+    }
+
+    final availableWidth = commandsPanel.size.x - 24;
+    final availableHeight = commandsPanel.size.y - (top + 14);
+    final cardHeight =
+        ((availableHeight - ((entries.length - 1) * gap)) / entries.length)
+            .clamp(
+              layout.mode == BattleCommandPanelLayoutMode.stacked ? 36.0 : 42.0,
+              layout.mode == BattleCommandPanelLayoutMode.stacked ? 58.0 : 64.0,
+            )
+            .toDouble();
+
+    for (var index = 0; index < entries.length; index++) {
+      final entry = entries[index];
+      final snapshot = _buildPartyEntrySnapshot(
+        entrySize: Size(availableWidth, cardHeight),
+        speciesLabel: entry.speciesId,
+        levelLabel: 'Nv. ${entry.level}',
+        hpLabel: '${entry.currentHp}/${entry.maxHp} PV',
+        statusLabel: _medicineTargetStatusLabel(entry),
+        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
+      );
+      final card = _BattleMedicineTargetEntryComponent(
+        entry: entry,
+        position: Vector2(12, top + ((cardHeight + gap) * index)),
+        size: Vector2(availableWidth, cardHeight),
+        snapshot: snapshot,
+        isSelected: index == _selectedMedicineTargetIndex,
+        onPressed: onMedicineTargetEntrySelected,
+        compact: layout.mode == BattleCommandPanelLayoutMode.stacked,
+        interactionsEnabled: interactionsEnabled,
+        statusLabel: _medicineTargetStatusLabel(entry),
+      );
+      _interactiveComponents.add(card);
+      commandsPanel.add(card);
+    }
+  }
+
   String _hintFor(BattleCommandMenuModel menuModel) {
     if (menuModel.isContinueOnly) {
       return 'Enter / Space';
@@ -752,11 +846,30 @@ String _bagEntryStatusLabel(BattleBagMenuEntry entry) {
     BattleBagMenuDisabledReason.captureUnavailable => 'Indisponible',
     BattleBagMenuDisabledReason.currentRequestDisallowsBag => 'Indisponible',
     BattleBagMenuDisabledReason.medicineNotImplemented => 'Not implemented',
+    BattleBagMenuDisabledReason.unsupportedMedicine => 'Unsupported medicine',
     BattleBagMenuDisabledReason.unsupportedItem => 'Unsupported item',
     null => 'Indisponible',
   };
 }
 
+String _medicineTargetStatusLabel(BattleMedicineTargetEntry entry) {
+  if (entry.isActive) {
+    return 'Actif';
+  }
+  if (entry.isFainted) {
+    return 'K.O.';
+  }
+  if (entry.isSelectable) {
+    return 'OK';
+  }
+  return switch (entry.disabledReason) {
+    BattleMedicineTargetDisabledReason.fullHp => 'Full HP',
+    BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest =>
+      'Indisponible',
+    BattleMedicineTargetDisabledReason.fainted || null => 'K.O.',
+  };
+}
+
 String _humanizeBagItemId(String itemId) {
   final normalized = itemId.replaceAll('_', '-');
   if (normalized == 'poke-ball') {
@@ -1098,6 +1211,137 @@ class _BattlePartyEntryComponent extends PositionComponent with TapCallbacks {
   }
 }
 
+class _BattleMedicineTargetEntryComponent extends PositionComponent
+    with TapCallbacks {
+  _BattleMedicineTargetEntryComponent({
+    required this.entry,
+    required Vector2 position,
+    required Vector2 size,
+    required this.snapshot,
+    required this.isSelected,
+    required this.onPressed,
+    required this.statusLabel,
+    this.compact = false,
+    this.interactionsEnabled = true,
+  }) : super(
+          position: position,
+          size: size,
+          anchor: Anchor.topLeft,
+          priority: 32,
+        );
+
+  final BattleMedicineTargetEntry entry;
+  final BattlePartyEntrySnapshot snapshot;
+  final bool isSelected;
+  final void Function(BattleMedicineTargetEntry entry)? onPressed;
+  final String statusLabel;
+  final bool compact;
+  final bool interactionsEnabled;
+
+  @override
+  bool containsLocalPoint(Vector2 point) {
+    return point.x >= 0 &&
+        point.x <= size.x &&
+        point.y >= 0 &&
+        point.y <= size.y;
+  }
+
+  @override
+  void onTapDown(TapDownEvent event) {
+    if (!interactionsEnabled || !entry.isSelectable) {
+      return;
+    }
+    onPressed?.call(entry);
+  }
+
+  @override
+  void render(Canvas canvas) {
+    super.render(canvas);
+
+    final rect = Offset.zero & Size(size.x, size.y);
+    final cornerRadius = Radius.circular(compact ? 12 : 14);
+    final enabled = entry.isSelectable;
+    final backgroundTop = enabled
+        ? const Color(0xFF597FBF)
+        : entry.isActive
+            ? const Color(0xFF5B616A)
+            : const Color(0xFF444B58);
+    final backgroundBottom = enabled
+        ? const Color(0xFF3C5A93)
+        : entry.isActive
+            ? const Color(0xFF41464E)
+            : const Color(0xFF323844);
+
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(rect, cornerRadius),
+      Paint()
+        ..shader = LinearGradient(
+          colors: <Color>[backgroundTop, backgroundBottom],
+          begin: Alignment.topLeft,
+          end: Alignment.bottomRight,
+        ).createShader(rect),
+    );
+    canvas.drawRRect(
+      RRect.fromRectAndRadius(rect, cornerRadius),
+      Paint()
+        ..style = PaintingStyle.stroke
+        ..strokeWidth = isSelected ? 2.25 : 1.1
+        ..color = isSelected
+            ? const Color(0xFFF7F0D4)
+            : enabled
+                ? const Color(0x55FFFFFF)
+                : const Color(0x33FFFFFF),
+    );
+
+    final titleColor =
+        enabled ? const Color(0xFFFDFDFD) : const Color(0xD8F1F4FA);
+    final metaColor =
+        enabled ? const Color(0xE6E7EFFA) : const Color(0xB6D5DDE8);
+    final statusColor = switch (entry.disabledReason) {
+      BattleMedicineTargetDisabledReason.fainted => const Color(0xFFFFB0A5),
+      BattleMedicineTargetDisabledReason.fullHp => const Color(0xFFEFDDA8),
+      _ => enabled ? const Color(0xFFC8F0CF) : const Color(0xD5DDE8F1),
+    };
+
+    _paintButtonText(
+      canvas,
+      text: entry.speciesId,
+      rect: snapshot.titleRect,
+      fontSize: snapshot.titleFontSize,
+      color: titleColor,
+      align: TextAlign.left,
+      fontWeight: FontWeight.w900,
+    );
+    _paintButtonText(
+      canvas,
+      text: 'Nv. ${entry.level}',
+      rect: snapshot.levelRect,
+      fontSize: snapshot.levelFontSize,
+      color: metaColor,
+      align: TextAlign.right,
+      fontWeight: FontWeight.w800,
+    );
+    _paintButtonText(
+      canvas,
+      text: '${entry.currentHp}/${entry.maxHp} PV',
+      rect: snapshot.hpRect,
+      fontSize: snapshot.metaFontSize,
+      color: metaColor,
+      align: TextAlign.left,
+      fontWeight: FontWeight.w700,
+    );
+    _paintButtonText(
+      canvas,
+      text: statusLabel,
+      rect: snapshot.statusRect,
+      fontSize: snapshot.metaFontSize,
+      color: statusColor,
+      align: TextAlign.right,
+      fontWeight: FontWeight.w800,
+    );
+  }
+}
+
 class _BattleBagEntryComponent extends PositionComponent with TapCallbacks {
   _BattleBagEntryComponent({
     required this.entry,
```

### `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
index 22ab95f7..a722bb18 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
@@ -12,6 +12,7 @@ import 'battle_command_panel_component.dart';
 import 'battle_combatant_gender_resolver.dart';
 import 'battle_background_resolver.dart';
 import 'battle_debug_panel_component.dart';
+import 'battle_medicine_target_menu_model.dart';
 import 'battle_party_menu_model.dart';
 import 'battle_pokemon_sprite_resolver.dart';
 import 'battle_visual_asset_cache.dart';
@@ -166,6 +167,38 @@ List<String> buildBattleBagNarrationLinesForOverlay(
   };
 }
 
+String buildBattleMedicineTargetPromptForOverlay(
+  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
+  String? feedbackMessage,
+}) {
+  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
+    return feedbackMessage;
+  }
+  if (medicineTargetMenuModel.itemId == 'potion') {
+    return 'Choisis une cible pour Potion.';
+  }
+  return 'Choisis un Pokémon.';
+}
+
+List<String> buildBattleMedicineTargetNarrationLinesForOverlay(
+  BattleMedicineTargetMenuModel medicineTargetMenuModel, {
+  String? feedbackMessage,
+}) {
+  if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
+    return const <String>[
+      'Aucun soin ni objet consommé dans ce lot.',
+    ];
+  }
+  if (!medicineTargetMenuModel.hasSelectableEntries) {
+    return const <String>[
+      'Aucune cible valide pour cet objet.',
+    ];
+  }
+  return const <String>[
+    'Les Pokémon K.O. et full HP sont indisponibles.',
+  ];
+}
+
 /// Construit les lignes du panneau debug optionnel.
 ///
 /// Ce panneau ne sert qu'au diagnostic local. Il doit rester :
@@ -373,7 +406,9 @@ class BattleOverlayComponent extends PositionComponent {
   int _selectedChoiceIndex = 0;
   int _selectedPartyIndex = 0;
   int _selectedBagIndex = 0;
+  int _selectedMedicineTargetIndex = 0;
   String? _bagFeedbackMessage;
+  BattleBagMenuActionMedicineTarget? _selectedMedicineAction;
 
   static const double _presentationEffectDelaySeconds = 0.16;
   static const double _presentationImpactStepSeconds = 0.62;
@@ -527,6 +562,7 @@ class BattleOverlayComponent extends PositionComponent {
       onRootActionSelected: _handleRootActionSelected,
       onPartyEntrySelected: _handlePartyEntrySelected,
       onBagEntrySelected: _handleBagEntrySelected,
+      onMedicineTargetEntrySelected: _handleMedicineTargetEntrySelected,
       layoutModeOverride: layout.commandPanelLayoutMode,
     );
     await add(_commandPanel!);
@@ -583,6 +619,8 @@ class BattleOverlayComponent extends PositionComponent {
     if (gameState != null) {
       _gameState = gameState;
     }
+    _selectedMedicineAction = null;
+    _selectedMedicineTargetIndex = 0;
     _bagFeedbackMessage = null;
     _startTurnPresentation(presentationSteps);
     _normalizeMenuSelection();
@@ -611,7 +649,8 @@ class BattleOverlayComponent extends PositionComponent {
       return null;
     }
     final menuModel = _currentMenuModel();
-    if (menuModel.mode == BattleCommandMenuMode.bag) {
+    if (menuModel.mode == BattleCommandMenuMode.bag ||
+        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
       return null;
     }
     final partyMenuModel = _currentPartyMenuModel();
@@ -636,6 +675,7 @@ class BattleOverlayComponent extends PositionComponent {
     final menuModel = _currentMenuModel();
     final partyMenuModel = _currentPartyMenuModel();
     final bagMenuModel = _currentBagMenuModel();
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
     if (menuModel.isContinueOnly) {
       final selectedChoice = menuModel.choiceEntries.first.choice;
       _handleChoiceSelected(selectedChoice);
@@ -675,6 +715,22 @@ class BattleOverlayComponent extends PositionComponent {
       _handleBagEntrySelected(selectedEntry);
       return true;
     }
+    if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
+      if (medicineTargetMenuModel == null ||
+          medicineTargetMenuModel.entries.isEmpty) {
+        return false;
+      }
+      final safeIndex = _selectedMedicineTargetIndex.clamp(
+        0,
+        medicineTargetMenuModel.entries.length - 1,
+      );
+      final selectedEntry = medicineTargetMenuModel.entries[safeIndex];
+      if (!selectedEntry.isSelectable) {
+        return false;
+      }
+      _handleMedicineTargetEntrySelected(selectedEntry);
+      return true;
+    }
     final selectedChoice =
         menuModel.choiceEntries[menuModel.selectedChoiceIndex].choice;
     _handleChoiceSelected(selectedChoice);
@@ -695,6 +751,14 @@ class BattleOverlayComponent extends PositionComponent {
           partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement) {
         return false;
       }
+      if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget) {
+        _selectedMedicineAction = null;
+        _selectedMedicineTargetIndex = 0;
+        _bagFeedbackMessage = null;
+        _menuMode = BattleCommandMenuMode.bag;
+        _syncPanelsOnly();
+        return true;
+      }
       _bagFeedbackMessage = null;
       _menuMode = BattleCommandMenuMode.root;
       _syncPanelsOnly();
@@ -824,6 +888,7 @@ class BattleOverlayComponent extends PositionComponent {
     final menuModel = _currentMenuModel();
     final partyMenuModel = _currentPartyMenuModel();
     final bagMenuModel = _currentBagMenuModel();
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
     final currentPresentationStep = _currentTurnPresentationStep;
     final isPresenting = currentPresentationStep != null;
     final partyPrompt = menuModel.mode == BattleCommandMenuMode.pokemon
@@ -844,23 +909,43 @@ class BattleOverlayComponent extends PositionComponent {
             feedbackMessage: _bagFeedbackMessage,
           )
         : null;
+    final medicineTargetPrompt =
+        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
+                medicineTargetMenuModel != null
+            ? buildBattleMedicineTargetPromptForOverlay(
+                medicineTargetMenuModel,
+                feedbackMessage: _bagFeedbackMessage,
+              )
+            : null;
+    final medicineTargetNarration =
+        menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
+                medicineTargetMenuModel != null
+            ? buildBattleMedicineTargetNarrationLinesForOverlay(
+                medicineTargetMenuModel,
+                feedbackMessage: _bagFeedbackMessage,
+              )
+            : null;
 
     _commandPanel?.sync(
       battleLabel: _titleForSession(),
       prompt: currentPresentationStep?.message ??
+          medicineTargetPrompt ??
           bagPrompt ??
           partyPrompt ??
           buildBattleDecisionPromptForOverlay(_session.decisionRequest),
       narrationLines: isPresenting
           ? const <String>[]
-          : (bagNarration ??
+          : (medicineTargetNarration ??
+              bagNarration ??
               partyNarration ??
               buildBattleNarrationLinesForOverlay(_session)),
       menuModel: menuModel,
       partyMenuModel: partyMenuModel,
       bagMenuModel: bagMenuModel,
+      medicineTargetMenuModel: medicineTargetMenuModel,
       selectedPartyIndex: _selectedPartyIndex,
       selectedBagIndex: _selectedBagIndex,
+      selectedMedicineTargetIndex: _selectedMedicineTargetIndex,
       allowEmptyNarrationBody: isPresenting,
       interactionsEnabled: !isPresenting,
     );
@@ -885,6 +970,7 @@ class BattleOverlayComponent extends PositionComponent {
     final menuModel = _currentMenuModel();
     final partyMenuModel = _currentPartyMenuModel();
     final bagMenuModel = _currentBagMenuModel();
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
     if (menuModel.isContinueOnly) {
       return false;
     }
@@ -939,6 +1025,25 @@ class BattleOverlayComponent extends PositionComponent {
       return true;
     }
 
+    if (menuModel.mode == BattleCommandMenuMode.bagMedicineTarget &&
+        medicineTargetMenuModel != null &&
+        medicineTargetMenuModel.entries.isNotEmpty) {
+      final nextIndex = moveBattleCommandGridSelection(
+        currentIndex: _selectedMedicineTargetIndex,
+        itemCount: medicineTargetMenuModel.entries.length,
+        columnCount: 1,
+        horizontalDelta: 0,
+        verticalDelta: verticalDelta,
+      );
+      if (nextIndex == _selectedMedicineTargetIndex) {
+        return false;
+      }
+      _selectedMedicineTargetIndex = nextIndex;
+      _bagFeedbackMessage = null;
+      _syncPanelsOnly();
+      return true;
+    }
+
     final nextIndex = moveBattleCommandGridSelection(
       currentIndex: menuModel.selectedChoiceIndex,
       itemCount: menuModel.choiceEntries.length,
@@ -966,6 +1071,17 @@ class BattleOverlayComponent extends PositionComponent {
     onPlayerChoice(choice);
   }
 
+  void _handleMedicineTargetEntrySelected(BattleMedicineTargetEntry entry) {
+    if (!entry.isSelectable) {
+      return;
+    }
+    final itemLabel =
+        _selectedMedicineAction?.itemId == 'potion' ? 'Potion' : 'Cet objet';
+    _bagFeedbackMessage =
+        'L’utilisation de $itemLabel sera branchée au prochain lot.';
+    _syncPanelsOnly();
+  }
+
   void _handleBagEntrySelected(BattleBagMenuEntry entry) {
     if (!entry.isSelectable) {
       return;
@@ -976,9 +1092,13 @@ class BattleOverlayComponent extends PositionComponent {
       onPlayerChoice(playerChoice);
       return;
     }
-    _bagFeedbackMessage =
-        'L’utilisation des objets sera branchée au prochain lot.';
-    _syncPanelsOnly();
+    if (action case BattleBagMenuActionMedicineTarget()) {
+      _selectedMedicineAction = action;
+      _selectedMedicineTargetIndex = _firstSelectableMedicineTargetIndex();
+      _bagFeedbackMessage = null;
+      _menuMode = BattleCommandMenuMode.bagMedicineTarget;
+      _syncPanelsOnly();
+    }
   }
 
   void _handleRootActionSelected(BattleCommandRootAction action) {
@@ -990,6 +1110,8 @@ class BattleOverlayComponent extends PositionComponent {
         _syncPanelsOnly();
         return;
       case BattleCommandRootAction.bag:
+        _selectedMedicineAction = null;
+        _selectedMedicineTargetIndex = 0;
         _menuMode = BattleCommandMenuMode.bag;
         _selectedBagIndex = _firstSelectableBagIndex();
         _syncPanelsOnly();
@@ -1030,12 +1152,28 @@ class BattleOverlayComponent extends PositionComponent {
     );
   }
 
+  BattleMedicineTargetMenuModel? _currentMedicineTargetMenuModel() {
+    final selectedMedicineAction = _selectedMedicineAction;
+    if (selectedMedicineAction == null) {
+      return null;
+    }
+    return buildBattleMedicineTargetMenuModel(
+      session: _session,
+      itemId: selectedMedicineAction.itemId,
+      categoryId: selectedMedicineAction.categoryId,
+    );
+  }
+
   BattleCommandMenuMode _effectiveMenuMode() {
     final partyMenuModel = _currentPartyMenuModel();
     if (partyMenuModel.mode == BattlePartyMenuMode.forcedReplacement &&
         partyMenuModel.hasSelectableEntries) {
       return BattleCommandMenuMode.pokemon;
     }
+    if (_menuMode == BattleCommandMenuMode.bagMedicineTarget &&
+        _selectedMedicineAction == null) {
+      return BattleCommandMenuMode.bag;
+    }
     return _menuMode;
   }
 
@@ -1044,6 +1182,7 @@ class BattleOverlayComponent extends PositionComponent {
     final menuModel = _currentMenuModel();
     final partyMenuModel = _currentPartyMenuModel();
     final bagMenuModel = _currentBagMenuModel();
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
     _menuMode = menuModel.mode;
     _selectedRootIndex = _firstEnabledRootIndex(
       rootEntries: menuModel.rootEntries,
@@ -1060,6 +1199,14 @@ class BattleOverlayComponent extends PositionComponent {
       previousMenuMode: previousMenuMode,
       nextMenuMode: menuModel.mode,
     );
+    _selectedMedicineTargetIndex = _normalizeSelectedMedicineTargetIndex(
+      medicineTargetMenuModel: medicineTargetMenuModel,
+      previousMenuMode: previousMenuMode,
+      nextMenuMode: menuModel.mode,
+    );
+    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget) {
+      _selectedMedicineAction = null;
+    }
   }
 
   void _syncMenuStateFromModel() {
@@ -1067,6 +1214,7 @@ class BattleOverlayComponent extends PositionComponent {
     final menuModel = _currentMenuModel();
     final partyMenuModel = _currentPartyMenuModel();
     final bagMenuModel = _currentBagMenuModel();
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
     _menuMode = menuModel.mode;
     _selectedRootIndex = menuModel.selectedRootIndex;
     _selectedChoiceIndex = menuModel.selectedChoiceIndex;
@@ -1080,6 +1228,14 @@ class BattleOverlayComponent extends PositionComponent {
       previousMenuMode: previousMenuMode,
       nextMenuMode: menuModel.mode,
     );
+    _selectedMedicineTargetIndex = _normalizeSelectedMedicineTargetIndex(
+      medicineTargetMenuModel: medicineTargetMenuModel,
+      previousMenuMode: previousMenuMode,
+      nextMenuMode: menuModel.mode,
+    );
+    if (_menuMode != BattleCommandMenuMode.bagMedicineTarget) {
+      _selectedMedicineAction = null;
+    }
   }
 
   int _firstEnabledRootIndex({
@@ -1109,6 +1265,14 @@ class BattleOverlayComponent extends PositionComponent {
     return _firstSelectableBagIndexFor(_currentBagMenuModel());
   }
 
+  int _firstSelectableMedicineTargetIndex() {
+    final medicineTargetMenuModel = _currentMedicineTargetMenuModel();
+    if (medicineTargetMenuModel == null) {
+      return 0;
+    }
+    return _firstSelectableMedicineTargetIndexFor(medicineTargetMenuModel);
+  }
+
   int _firstSelectablePartyIndexFor(BattlePartyMenuModel partyMenuModel) {
     for (var index = 0; index < partyMenuModel.allEntries.length; index++) {
       if (partyMenuModel.allEntries[index].isSelectable) {
@@ -1127,6 +1291,19 @@ class BattleOverlayComponent extends PositionComponent {
     return 0;
   }
 
+  int _firstSelectableMedicineTargetIndexFor(
+    BattleMedicineTargetMenuModel medicineTargetMenuModel,
+  ) {
+    for (var index = 0;
+        index < medicineTargetMenuModel.entries.length;
+        index++) {
+      if (medicineTargetMenuModel.entries[index].isSelectable) {
+        return index;
+      }
+    }
+    return 0;
+  }
+
   int _normalizeSelectedPartyIndex({
     required BattlePartyMenuModel partyMenuModel,
     required BattleCommandMenuMode previousMenuMode,
@@ -1170,6 +1347,28 @@ class BattleOverlayComponent extends PositionComponent {
     return safeIndex;
   }
 
+  int _normalizeSelectedMedicineTargetIndex({
+    required BattleMedicineTargetMenuModel? medicineTargetMenuModel,
+    required BattleCommandMenuMode previousMenuMode,
+    required BattleCommandMenuMode nextMenuMode,
+  }) {
+    if (medicineTargetMenuModel == null ||
+        medicineTargetMenuModel.entries.isEmpty) {
+      return 0;
+    }
+    final safeIndex = _selectedMedicineTargetIndex.clamp(
+      0,
+      medicineTargetMenuModel.entries.length - 1,
+    );
+    if (nextMenuMode != BattleCommandMenuMode.bagMedicineTarget) {
+      return safeIndex;
+    }
+    if (previousMenuMode != BattleCommandMenuMode.bagMedicineTarget) {
+      return _firstSelectableMedicineTargetIndexFor(medicineTargetMenuModel);
+    }
+    return safeIndex;
+  }
+
   void _syncOutcomeBanner() {
     if (!_session.state.isFinished || _session.state.outcome == null) {
       _outcomeBanner?.removeFromParent();
```

### `packages/map_runtime/test/battle_bag_menu_model_test.dart`

```diff
diff --git a/packages/map_runtime/test/battle_bag_menu_model_test.dart b/packages/map_runtime/test/battle_bag_menu_model_test.dart
index e7620905..fa23a43a 100644
--- a/packages/map_runtime/test/battle_bag_menu_model_test.dart
+++ b/packages/map_runtime/test/battle_bag_menu_model_test.dart
@@ -135,7 +135,8 @@ void main() {
       expect(model.hasSelectableEntries, isFalse);
     });
 
-    test('wild battle with poke-ball and allowed capture exposes a selectable capture entry',
+    test(
+        'wild battle with poke-ball and allowed capture exposes a selectable capture entry',
         () {
       final session = _session(
         player: _combatant(
@@ -217,7 +218,8 @@ void main() {
       expect(entry.action, isNull);
     });
 
-    test('wild battle with poke-ball but full party keeps capture disabled with an explicit reason',
+    test(
+        'wild battle with poke-ball but full party keeps capture disabled with an explicit reason',
         () {
       final session = _session(
         player: _combatant(
@@ -347,7 +349,9 @@ void main() {
       );
     });
 
-    test('medicine stays visible with a non-implemented disabled reason', () {
+    test(
+        'supported potion is selectable in a free turn and opens a medicine target action',
+        () {
       final session = _session(
         player: _combatant(
           speciesId: 'sproutle',
@@ -376,10 +380,97 @@ void main() {
       final entry = model.entries.single;
       expect(entry.kind, equals(BattleBagItemKind.medicine));
       expect(entry.quantity, equals(4));
+      expect(entry.isSelectable, isTrue);
+      expect(entry.disabledReason, isNull);
+      expect(
+        entry.action,
+        isA<BattleBagMenuActionMedicineTarget>()
+            .having((action) => action.itemId, 'itemId', equals('potion'))
+            .having(
+              (action) => action.categoryId,
+              'categoryId',
+              equals('medicine'),
+            )
+            .having((action) => action.quantity, 'quantity', equals(4)),
+      );
+    });
+
+    test('unsupported medicine stays visible but disabled', () {
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'wildmon',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+        ),
+        allowCapture: true,
+      );
+
+      final model = buildBattleBagMenuModel(
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _entry(itemId: 'antidote', categoryId: 'medicine', quantity: 2),
+            ],
+          ),
+        ),
+        session: session,
+      );
+
+      final entry = model.entries.single;
+      expect(entry.kind, equals(BattleBagItemKind.medicine));
+      expect(entry.quantity, equals(2));
+      expect(entry.isSelectable, isFalse);
+      expect(
+        entry.disabledReason,
+        equals(BattleBagMenuDisabledReason.unsupportedMedicine),
+      );
+      expect(entry.action, isNull);
+    });
+
+    test('potion is non-selectable when the current request disallows bag', () {
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 0,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        playerReserve: <BattleCombatantData>[
+          _combatant(
+            speciesId: 'benchmon',
+            lineupIndex: 1,
+            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+          ),
+        ],
+        enemy: _combatant(
+          speciesId: 'wildmon',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+        ),
+      );
+
+      final model = buildBattleBagMenuModel(
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _entry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+            ],
+          ),
+        ),
+        session: session,
+      );
+
+      final entry = model.entries.single;
+      expect(entry.kind, equals(BattleBagItemKind.medicine));
       expect(entry.isSelectable, isFalse);
       expect(
         entry.disabledReason,
-        equals(BattleBagMenuDisabledReason.medicineNotImplemented),
+        equals(BattleBagMenuDisabledReason.currentRequestDisallowsBag),
       );
       expect(entry.action, isNull);
     });
@@ -454,7 +545,8 @@ void main() {
       expect(model.entries[1].quantity, equals(4));
     });
 
-    test('capture action is never synthesized when the current request does not allow it',
+    test(
+        'capture action is never synthesized when the current request does not allow it',
         () {
       final session = _session(
         player: _combatant(
```

### `packages/map_runtime/test/battle_command_menu_component_test.dart`

```diff
diff --git a/packages/map_runtime/test/battle_command_menu_component_test.dart b/packages/map_runtime/test/battle_command_menu_component_test.dart
index 696622f4..e490cfaf 100644
--- a/packages/map_runtime/test/battle_command_menu_component_test.dart
+++ b/packages/map_runtime/test/battle_command_menu_component_test.dart
@@ -619,7 +619,8 @@ void main() {
       expect(panel.currentSelectedBagIndex, 0);
     });
 
-    test('battle bag submenu renders disabled medicine and unsupported items',
+    test(
+        'battle bag submenu renders selectable potion and disabled unsupported entries',
         () async {
       final overlay = BattleOverlayComponent(
         session: _session(
@@ -643,6 +644,11 @@ void main() {
           bag: Bag(
             entries: <BagEntry>[
               _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
+              _bagEntry(
+                itemId: 'antidote',
+                categoryId: 'medicine',
+                quantity: 1,
+              ),
               _bagEntry(
                 itemId: 'rare-candy',
                 categoryId: 'items',
@@ -664,13 +670,95 @@ void main() {
       expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
       expect(
         panel.currentBagEntryLabels,
-        const <String>['Rare Candy x1', 'Potion x2'],
+        const <String>['Rare Candy x1', 'Antidote x1', 'Potion x2'],
+      );
+      expect(
+        panel.currentBagSelectableStates,
+        const <bool>[false, false, true],
       );
-      expect(panel.currentBagSelectableStates, const <bool>[false, false]);
       expect(
         panel.currentBagStatusLabels,
-        const <String>['Unsupported item', 'Not implemented'],
+        const <String>['Unsupported item', 'Unsupported medicine', 'OK'],
+      );
+    });
+
+    test('battle medicine target submenu shows active and reserve pokemon',
+        () async {
+      final overlay = BattleOverlayComponent(
+        session: _session(
+          player: _combatant(
+            speciesId: 'charmander',
+            lineupIndex: 0,
+            currentHp: 24,
+            maxHp: 40,
+            moves: <BattleMoveData>[
+              _move(id: 'scratch', name: 'Scratch'),
+            ],
+          ),
+          playerReserve: <BattleCombatantData>[
+            _combatant(
+              speciesId: 'bulbasaur',
+              lineupIndex: 1,
+              currentHp: 30,
+              maxHp: 30,
+              moves: <BattleMoveData>[
+                _move(id: 'vine_whip', name: 'Vine Whip'),
+              ],
+            ),
+            _combatant(
+              speciesId: 'squirtle',
+              lineupIndex: 2,
+              currentHp: 0,
+              maxHp: 35,
+              moves: <BattleMoveData>[
+                _move(id: 'tackle', name: 'Tackle'),
+              ],
+            ),
+          ],
+          enemy: _combatant(
+            speciesId: 'pidgey',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[
+              _move(id: 'tackle', name: 'Tackle'),
+            ],
+          ),
+          isTrainerBattle: false,
+        ),
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
+            ],
+          ),
+        ),
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (_) {},
+      );
+
+      await overlay.onLoad();
+      final panel = _panelFromOverlay(overlay);
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.validateSelectedChoice(), isTrue);
+
+      expect(
+        overlay.currentMenuMode,
+        BattleCommandMenuMode.bagMedicineTarget,
+      );
+      expect(
+        panel.currentMedicineTargetSpeciesLabels,
+        const <String>['charmander', 'bulbasaur', 'squirtle'],
+      );
+      expect(
+        panel.currentMedicineTargetSelectableStates,
+        const <bool>[true, false, false],
       );
+      expect(
+        panel.currentMedicineTargetStatusLabels,
+        const <String>['Actif', 'Full HP', 'K.O.'],
+      );
+      expect(panel.currentSelectedMedicineTargetIndex, equals(0));
     });
 
     test(
```

### `packages/map_runtime/test/battle_overlay_component_test.dart`

```diff
diff --git a/packages/map_runtime/test/battle_overlay_component_test.dart b/packages/map_runtime/test/battle_overlay_component_test.dart
index 03cd893d..3b2eb93e 100644
--- a/packages/map_runtime/test/battle_overlay_component_test.dart
+++ b/packages/map_runtime/test/battle_overlay_component_test.dart
@@ -1129,7 +1129,8 @@ void main() {
       expect(pickedChoice, isNull);
     });
 
-    test('selecting a capture-capable poke ball dispatches PlayerBattleChoiceCapture',
+    test(
+        'selecting a capture-capable poke ball dispatches PlayerBattleChoiceCapture',
         () async {
       PlayerBattleChoice? pickedChoice;
       final session = _session(
@@ -1184,7 +1185,8 @@ void main() {
       expect(overlay.getSelectedChoice(), isNull);
     });
 
-    test('selecting disabled poke ball in trainer battle does not dispatch capture',
+    test(
+        'selecting disabled poke ball in trainer battle does not dispatch capture',
         () async {
       PlayerBattleChoice? pickedChoice;
       final overlay = BattleOverlayComponent(
@@ -1221,7 +1223,8 @@ void main() {
       expect(pickedChoice, isNull);
     });
 
-    test('selecting medicine from battle bag does not dispatch a battle choice',
+    test(
+        'selecting potion from battle bag opens the medicine target shell without dispatching',
         () async {
       PlayerBattleChoice? pickedChoice;
       final overlay = BattleOverlayComponent(
@@ -1253,10 +1256,231 @@ void main() {
       overlay.moveSelectionRight();
       expect(overlay.validateSelectedChoice(), isTrue);
       expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
-      expect(overlay.validateSelectedChoice(), isFalse);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(
+        overlay.currentMenuMode,
+        BattleCommandMenuMode.bagMedicineTarget,
+      );
+      final commandPanel =
+          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      expect(
+        commandPanel.currentMedicineTargetSpeciesLabels,
+        const <String>['sproutle'],
+      );
       expect(pickedChoice, isNull);
     });
 
+    test(
+        'selecting a valid medicine target shows shell feedback without dispatching or mutating state',
+        () async {
+      PlayerBattleChoice? pickedChoice;
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 12,
+          maxHp: 40,
+          moves: <BattleMoveData>[_tackle()],
+        ),
+        playerReserve: <BattleCombatantData>[
+          _combatant(
+            speciesId: 'benchmate',
+            lineupIndex: 1,
+            currentHp: 40,
+            maxHp: 40,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+        ],
+        enemy: _combatant(
+          speciesId: 'wild_enemy',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_tackle()],
+        ),
+      );
+      final gameState = _gameState(
+        bag: Bag(
+          entries: <BagEntry>[
+            _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+          ],
+        ),
+      );
+      final overlay = BattleOverlayComponent(
+        session: session,
+        gameState: gameState,
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (choice) => pickedChoice = choice,
+      );
+
+      await overlay.onLoad();
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.validateSelectedChoice(), isTrue);
+
+      final playerHpBefore = session.state.player.currentHp;
+      expect(overlay.validateSelectedChoice(), isTrue);
+
+      final commandPanel =
+          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      expect(pickedChoice, isNull);
+      expect(session.state.player.currentHp, equals(playerHpBefore));
+      expect(gameState.bag.entries.single.quantity, equals(1));
+      expect(
+        overlay.currentPromptText,
+        equals('L’utilisation de Potion sera branchée au prochain lot.'),
+      );
+      expect(
+        commandPanel.currentMedicineTargetSpeciesLabels,
+        const <String>['sproutle', 'benchmate'],
+      );
+    });
+
+    test('full hp medicine targets stay visible but non-selectable', () async {
+      final overlay = BattleOverlayComponent(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 40,
+            maxHp: 40,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+          playerReserve: <BattleCombatantData>[
+            _combatant(
+              speciesId: 'benchmate',
+              lineupIndex: 1,
+              currentHp: 35,
+              maxHp: 35,
+              moves: <BattleMoveData>[_tackle()],
+            ),
+          ],
+          enemy: _combatant(
+            speciesId: 'wild_enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+        ),
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+            ],
+          ),
+        ),
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (_) {},
+      );
+
+      await overlay.onLoad();
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.validateSelectedChoice(), isTrue);
+
+      final commandPanel =
+          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      expect(
+        commandPanel.currentMedicineTargetSelectableStates,
+        const <bool>[false, false],
+      );
+      expect(overlay.validateSelectedChoice(), isFalse);
+    });
+
+    test('fainted medicine targets stay visible but non-selectable', () async {
+      final overlay = BattleOverlayComponent(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 15,
+            maxHp: 40,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+          playerReserve: <BattleCombatantData>[
+            _combatant(
+              speciesId: 'fainted_bench',
+              lineupIndex: 1,
+              currentHp: 0,
+              maxHp: 35,
+              moves: <BattleMoveData>[_tackle()],
+            ),
+          ],
+          enemy: _combatant(
+            speciesId: 'wild_enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+        ),
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+            ],
+          ),
+        ),
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (_) {},
+      );
+
+      await overlay.onLoad();
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      overlay.moveSelectionDown();
+
+      final commandPanel =
+          overlay.children.whereType<BattleCommandPanelComponent>().single;
+      expect(commandPanel.currentSelectedMedicineTargetIndex, equals(1));
+      expect(
+        commandPanel.currentMedicineTargetStatusLabels,
+        const <String>['Actif', 'K.O.'],
+      );
+      expect(overlay.validateSelectedChoice(), isFalse);
+    });
+
+    test('escape from medicine target returns to bag and then to root',
+        () async {
+      final overlay = BattleOverlayComponent(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 12,
+            maxHp: 40,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+          enemy: _combatant(
+            speciesId: 'wild_enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_tackle()],
+          ),
+        ),
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _bagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
+            ],
+          ),
+        ),
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (_) {},
+      );
+
+      await overlay.onLoad();
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
+
+      expect(overlay.handleEscape(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+
+      expect(overlay.handleEscape(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.root);
+    });
+
     test('updateState refreshes bag menu source', () async {
       final initialSession = _session(
         player: _combatant(
```

## Décision finale

Le lot 9-c est réussi.

Le BAG runtime sait maintenant transformer `Potion` en un vrai shell de ciblage party honnête, visible, navigable et testé, sans soin réel, sans consommation d'objet et sans dispatch de choix battle. Le prochain lot naturel est le branchement réel de l'usage medicine sur le runtime battle/write-back, sans réouvrir le shell UI construit ici.
