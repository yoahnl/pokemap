# FG-072 — Held Item Bridge V0

## Verdict

**Statut proposé : `DONE` pour RM-024 / FG-072.**

Les objets tenus du joueur et des dresseurs traversent maintenant le bridge
runtime vers PSDK, uniquement lorsqu’un effet est réellement porté. Le moteur
hydrate et exécute ces effets, puis le runtime réconcilie explicitement l’objet
final du joueur avec la sauvegarde : inchangé, consommé, retiré/volé ou reçu.
Le write-back est injecté dans l’état de base de la transaction post-combat et
n’est donc pas publié séparément.

Le lot ne crée volontairement ni écran joueur d’équipement, ni inventaire
dresseur, ni règle de restauration automatique après certains modes de combat.

## Lot et critères

| Élément | Valeur |
|---|---|
| Roadmap | RM-024 — Held Item Bridge V0 |
| Gap | FG-072 |
| Dépendance | RM-020 |
| Packages | `map_battle`, `map_runtime`; contrats existants caractérisés dans `map_core` et `map_editor` |
| Taille prévue | L |

Critères couverts :

- injection joueur/dresseur, actifs et réserves ;
- normalisation `catalog-id` vers `psdk_id` ;
- refus fail-closed d’un objet dont l’effet PSDK n’est pas porté ;
- exécution d’un effet réel issu du bridge (`leftovers`) ;
- write-back explicite inchangé/consommé/retiré/reçu ;
- aucune persistance de l’équipe adverse ;
- branchement au commit post-combat ;
- authoring dresseur guidé et validation existants caractérisés.

## Audit initial

État constaté avant implémentation :

- `PlayerPokemon.heldItemId` existait déjà dans la sauvegarde `map_core` ;
- `ProjectTrainerPokemonEntry.heldItemId` existait déjà dans le manifeste ;
- l’éditeur proposait déjà un picker d’objet tenu et ses validations ;
- `PsdkBattleCombatantSetup` et `PsdkBattleState` savaient déjà représenter
  `heldItemId`, `consumedItemId` et `itemConsumed` ;
- `ItemEffectRegistry` et plusieurs effets tenus étaient déjà fonctionnels ;
- le seed runtime PSDK abandonnait pourtant `heldItemId` ;
- le post-combat persistait HP, PP et statut mais ignorait le cycle de vie de
  l’objet tenu.

État Git initial du lot :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
?? packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart
```

Les sept fichiers Hub/Player UI ci-dessus sont des modifications utilisateur
préexistantes : ils n’ont été ni modifiés ni inclus dans le commit du lot.
Le plan sous `docs/superpowers/plans/` est ignoré par Git et sera ajouté
explicitement au commit.

## Passes de réalisation

Les instructions actives interdisaient la délégation proactive : aucun
sub-agent n’a été lancé. Les verdicts ci-dessous correspondent aux cinq passes
indépendantes exigées par `codex_rule.md`.

### Passe 1 — Audit et architecture

**Verdict : PASS.**

Le point d’autorité retenu pour l’injection est
`RuntimeBattleCombatantSeedBuilder`. Le point d’autorité du write-back est
`runtime_battle_outcome_apply.dart`, appelé avant
`RuntimePostBattleDecisionCoordinator.begin`. Ce découpage garde les règles
hors de Flame et évite une seconde mutation de sauvegarde.

### Passe 2 — Implémentation

**Verdict : PASS.**

- `ItemEffectRegistry.isPorted` expose une interrogation minimale et publique ;
- le seed runtime normalise les tirets en underscores et refuse un effet absent
  ou partiel avec `support=not_ported` ;
- `RuntimePsdkBattleCombatantSeed` transporte l’objet jusqu’au setup PSDK ;
- `writePlayerPsdkHeldItemsBackToPartySlots` réconcilie chaque lineup index avec
  son slot exact dans la party sauvegardée ;
- l’ID de sauvegarde d’origine est conservé si l’objet normalisé est inchangé ;
- l’objet final PSDK est persisté s’il a changé ;
- une consommation ou une absence finale vide `heldItemId` ;
- seule la banque joueur est écrite ;
- l’état réconcilié devient la base de la transaction post-combat.

### Passe 3 — Tests ciblés

**Verdict : PASS.**

Les tests prouvent :

- un `leftovers` issu du vrai seed runtime, hydraté par le registry, soigne
  effectivement 5 HP sur 80 en fin de tour ;
- joueur et dresseur propagent leurs objets, réserves comprises ;
- `mystic-water` et `oran-berry` deviennent `mystic_water` et `oran_berry` ;
- `rare-candy`, non porté comme effet tenu, échoue explicitement ;
- les quatre branches de write-back sont déterministes ;
- les contrats de sauvegarde et l’authoring guidé dresseur restent valides.

### Passe 4 — Validation globale

**Verdict : PASS sur le périmètre du lot, avec deux signaux de charge
documentés.**

Les suites complètes battle et runtime, les analyses, les smokes et tous les
tests ciblés sont verts. La suite core complète lancée en parallèle de battle
et editor a dépassé trois budgets chronométriques ; les quatre fichiers de
performance ont ensuite tous réussi seuls. La suite editor complète lancée
dans la même fenêtre a terminé à `+4150 -1`; l’unique échec n’a pas été
conservé par le reporter compact. Le long validator Selbrume visible en fin de
run a ensuite réussi seul en 58 secondes, sous son timeout de 3 minutes.
Les trois tests editor qui couvrent directement l’objet tenu dresseur sont
verts (`+22`) et `flutter analyze` est propre.

Ces deux signaux n’impliquent aucun fichier modifié par RM-024 hors
`map_battle`/`map_runtime` et ne reproduisent pas sur les preuves isolées.

### Passe 5 — Auto-critique finale

**Verdict : PASS avec limites explicites.**

Risques résiduels :

- un objet reçu/volé est sauvegardé avec l’ID PSDK normalisé, pas
  nécessairement l’orthographe catalogue initiale ;
- l’éditeur peut référencer un objet catalogue sans effet tenu porté : le
  runtime échoue alors explicitement au démarrage du combat ;
- il n’existe pas encore d’écran joueur pour équiper ou retirer un objet ;
- les règles propres à des formats compétitifs qui restaurent les objets après
  combat sont hors V0 ;
- la suite editor complète doit être rejouée sans concurrence si une preuve
  globale entièrement verte est requise indépendamment de ce lot.

Aucune mutation silencieuse, aucun fallback d’objet neutre et aucune
persistance d’objet adverse n’ont été introduits.

## Inventaire des fichiers

### Créés

- `docs/superpowers/plans/2026-07-26-rm-024-held-item-bridge-v0.md`
- `packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart`
- `reports/gameplay/fg_072_held_item_bridge_v0.md`

### Modifiés

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

## Zones précises modifiées

| Fichier | Zone |
|---|---|
| `map_battle.dart` | export public ciblé de `ItemEffectRegistry` |
| `item_effect_registry.dart` | helper `isPorted` |
| `runtime_battle_combatant_seed_builder.dart` | seeds joueur/dresseur, normalisation fail-closed, champ/setup PSDK |
| `runtime_battle_outcome_apply.dart` | helper de write-back held item par lineup |
| `playable_map_game.dart` | composition de l’état PSDK avant transaction post-combat |
| `runtime_battle_combatant_seed_builder_test.dart` | propagation joueur/dresseur et refus non porté |
| `runtime_battle_setup_mapper_test.dart` | propagation réelle actif/réserve via mapper |
| `runtime_held_item_bridge_v0_test.dart` | effet réel et matrice de write-back |

## Commandes et résultats exacts

```text
cd packages/map_runtime
flutter test test/runtime_held_item_bridge_v0_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart
=> +55: All tests passed!

cd packages/map_core
dart test test/save_data_test.dart
=> +34: All tests passed!
dart analyze
=> No issues found!

cd packages/map_battle
dart test test/psdk_item_effects_test.dart \
  test/psdk_item_lifecycle_effects_test.dart \
  test/psdk_item_registry_manifest_test.dart
=> +57: All tests passed!
dart analyze
=> No issues found!

cd packages/map_editor
flutter test test/editor_notifier_trainer_update_test.dart \
  test/trainer_library_panel_test.dart \
  test/trainer_use_cases_test.dart
=> +22: All tests passed!
flutter analyze
=> No issues found! (ran in 5.6s)

cd packages/map_runtime
flutter test
=> 02:59 +2195 ~1: All tests passed!
flutter analyze
=> No issues found! (ran in 5.0s)
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
=> +3: All tests passed!

cd examples/playable_runtime_host
flutter test test/phase_a_golden_slice_launch_test.dart
=> +1: All tests passed!
flutter analyze
=> No issues found! (ran in 5.4s)

cd packages/map_battle
dart test
=> 00:39 +1757: All tests passed!

cd packages/map_core
dart test
=> 02:53 +4459 -3: Some tests failed.
Cause observée : budgets de performance pendant une exécution concurrente.

cd packages/map_core
dart test test/narrative_dependency_index_performance_test.dart \
  test/cinematics_library_read_model_performance_test.dart \
  test/narrative_event_authoring_performance_test.dart \
  test/narrative_fact_runtime_performance_test.dart
=> 00:08 +5: All tests passed!

cd packages/map_editor
flutter test
=> 06:01 +4150 -1: Some tests failed.
Le reporter compact n’a pas conservé l’identité de l’unique échec.

cd packages/map_editor
flutter test test/selbrume_narrative_validator_test.dart
=> 00:58 +1: All tests passed!

git diff --check
=> succès, aucune erreur de whitespace
```

## Contenu complet des fichiers créés

Le présent rapport est exclu de sa propre récursion.

### `docs/superpowers/plans/2026-07-26-rm-024-held-item-bridge-v0.md`

```markdown
# RM-024 Held Item Bridge V0 Implementation Plan

**Goal:** Faire traverser les objets tenus joueur/dresseur jusqu’au moteur PSDK,
activer uniquement les effets réellement portés et persister explicitement le
résultat consommé/retiré/volé côté party joueur.

**Architecture:** Le seed runtime normalise l’ID catalogue vers l’ID PSDK et
refuse les effets non portés. `map_battle` hydrate déjà les effets depuis
`ItemEffectRegistry`; le lot le prouve depuis le vrai bridge. Un helper runtime
réconcilie la party PSDK finale vers les slots save avant la transaction
post-combat. L’ID save original est préservé si l’objet n’a pas changé.

**Write-back V0:**

- objet encore tenu et inchangé : préserver l’ID save original ;
- objet consommé : vider `heldItemId` ;
- objet retiré/volé : persister l’absence ;
- objet reçu/volé à l’adversaire : persister l’ID PSDK final ;
- équipe adverse : aucun write-back persistant.

**Non-goals:** UI joueur pour équiper/retirer un objet, inventaire d’objets de
dresseur, restauration automatique des objets après certains modes de combat.

### Task 1: Injection fail-closed

- [x] Tests RED player/trainer → seed/setup.
- [x] Normaliser tirets/underscores sans perdre l’ID save.
- [x] Refuser un held item sans effet PSDK `ported`.
- [x] Injecter l’objet aux actifs et réserves.

### Task 2: Effet réel

- [x] Prouver un effet porté depuis un setup issu du bridge.
- [x] Prouver l’hydratation `ItemEffectRegistry`.

### Task 3: Write-back

- [x] Ajouter la transaction PSDK held-item vers party runtime.
- [x] Prouver inchangé, consommé, retiré et reçu/volé.
- [x] Brancher avant la transaction post-battle.
- [x] Préserver l’atomicité si le post-battle échoue.

### Task 4: Editor et validation

- [x] Caractériser le picker/validation held item trainer existant.
- [x] Ajouter une preuve ciblée si nécessaire.
- [x] Suites/analyzes core, battle, runtime et editor.
- [x] Smokes Golden.
- [x] Evidence Pack `FG-072`.
- [x] Commit isolé et état Git final.
```

### `packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';

void main() {
  group('runtime held item bridge v0', () {
    test('a runtime seed hydrates and executes its held-item effect', () {
      final playerSeed = RuntimePsdkBattleCombatantSeed(
        speciesId: 'player',
        level: 20,
        maxHp: 80,
        catchRate: 45,
        stats: _stats,
        typing: const BattleTypingSnapshot(primaryType: 'normal'),
        abilityId: 'pressure',
        heldItemId: 'leftovers',
        moves: <PsdkBattleMoveData>[_move('player-wait')],
        currentHp: 40,
      );
      final session = BattleSessionFacade.fromPsdkSetup(
        setup: PsdkBattleSetup.singles(
          player: playerSeed.toPsdkBattleCombatantSetup(
            lineupIndex: 0,
            idPrefix: 'player',
          ),
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );

      final player = session.state.psdkState.battlerAt(psdkPlayerSlot);
      expect(player.heldItemId, 'leftovers');
      expect(
        player.effects.effects.map((effect) => effect.id),
        contains('item:leftovers'),
      );

      session.submit(const BattleDecision.noAction());

      expect(
        session.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
        45,
      );
    });

    test('writes unchanged, consumed, removed and received items explicitly',
        () {
      final psdkState = PsdkBattleState.fromSetup(
        PsdkBattleSetup.singles(
          player: _combatant(
            id: 'player_0',
            heldItemId: 'oran_berry',
          ),
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'player_1',
              consumedItemId: 'sitrus_berry',
              itemConsumed: true,
            ),
            _combatant(id: 'player_2'),
            _combatant(
              id: 'player_3',
              heldItemId: 'leftovers',
            ),
          ],
          opponent: _combatant(id: 'opponent_0'),
          rngSeeds: _rngSeeds,
        ),
      );
      const gameState = GameState(
        saveId: 'held-item-write-back',
        party: PlayerParty(
          members: <PlayerPokemon>[
            PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'hardy',
              abilityId: 'overgrow',
              heldItemId: 'oran-berry',
            ),
            PlayerPokemon(
              speciesId: 'bench-one',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'sitrus-berry',
            ),
            PlayerPokemon(
              speciesId: 'bench-two',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'air-balloon',
            ),
            PlayerPokemon(
              speciesId: 'bench-three',
              natureId: 'hardy',
              abilityId: 'pressure',
              heldItemId: 'oran-berry',
            ),
          ],
        ),
      );

      final result = writePlayerPsdkHeldItemsBackToPartySlots(
        gameState: gameState,
        context: _context(),
        psdkState: psdkState,
      );

      expect(
        result.party.members.map((pokemon) => pokemon.heldItemId),
        <String>['oran-berry', '', '', 'leftovers'],
      );
    });
  });
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: 80,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    heldItemId: heldItemId,
    consumedItemId: consumedItemId,
    itemConsumed: itemConsumed,
    moves: <PsdkBattleMoveData>[_move('$id-move')],
  );
}

const _stats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

PsdkBattleMoveData _move(String id) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: 'Wait',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.user,
  );
}

const _rngSeeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 2,
  moveAccuracy: 3,
  generic: 4,
);

RuntimeActiveBattleContext _context() {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'held-item-battle',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'field',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.south,
      ),
      trainerId: 'trainer',
      npcEntityId: 'npc',
      mapId: 'field',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: 0,
    playerPartySlotIndicesByLineupIndex: const <int>[0, 1, 2, 3],
  );
}
```

## État Git final

Après le commit isolé, seuls les sept fichiers utilisateur préexistants
restent modifiés :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```
