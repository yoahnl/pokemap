# FG-050 — Generic Battle Items V0 — Evidence Pack

- Roadmap lot : **RM-023**
- Gameplay gap : **FG-050**
- Date : **2026-07-26**
- Verdict proposé : **DONE**
- Portée : medicines de soin PV, cures de statut et Revive en combat PSDK
- Branche : `main`

## 1. Résultat

Le runtime de combat possède désormais une transaction d’objet générique qui
résout l’effet depuis `PlayerItemEffectRegistry.mvp`, cible explicitement un
membre de la party PSDK, exige un reçu moteur `item_consumed`, écrit le
résultat battle sur le bon slot de sauvegarde, puis seulement débite le bag.

Le contrat couvre :

- Potion, Super Potion, Hyper Potion et Max Potion ;
- Antidote, Awakening, Paralyze Heal, Burn Heal, Ice Heal et Full Heal ;
- Revive à 50 % ;
- actif et réserves ;
- refus sans mutation pour cible invalide ou absence d’effet.

La restauration de PP reste dans RM-041 et les objets tenus dans RM-024.

## 2. Audit initial

Avant RM-023, trois morceaux existaient mais n’étaient pas reliés honnêtement :

1. `map_gameplay` possédait déjà le registre des effets et une transaction hors
   combat ;
2. `map_battle` acceptait seulement un soin PV dirigé vers le slot actif et ne
   portait ni index de party ni effet Revive ;
3. `map_runtime` reconnaissait quatre soins PV, interdisait les réserves sur le
   chemin PSDK et débitait via un helper spécialisé.

Le risque principal était une divergence d’inventaire : aucun contrat
n’imposait que le moteur accepte réellement l’effet avant la consommation du
bag runtime.

État Git initial observé avant le lot (changements utilisateur, hors scope) :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces sept fichiers n’ont été ni modifiés ni stagés par RM-023.

## 3. Décisions d’architecture

- `map_gameplay` reste propriétaire du catalogue canonique des effets joueur.
- `map_battle` reçoit un effet déjà résolu et une cible
  `targetPartyIndex` explicite.
- Le moteur met à jour la party PSDK et le slot actif de façon cohérente.
- Une décision item sans effet lève `BattleDecisionRejectedError` et restaure
  état, RNG et numéro de tour.
- L’événement `item_consumed` expose `partyIndex` et constitue le reçu
  obligatoire du runtime.
- Le runtime consomme une unité seulement après exactement un reçu concordant.
- L’overlay calcule les cibles depuis le type d’effet, sans IDs saisis à la main.
- Le wrapper HP historique reste disponible pour compatibilité.
- Aucun schéma de sauvegarde n’est modifié.

## 4. Passes indépendantes exigées

| Passe | Angle | Verdict |
|---|---|---|
| Audit / Architecture | frontières gameplay → battle → runtime, autorité du bag, cible de party | **ACCEPT** |
| Implémentation | contrat typé, mutation party/slot, transaction post-reçu | **ACCEPT** |
| Tests | RED initial, actif/réserve, heal/cure/revive, no-effect atomique | **ACCEPT** |
| Build / Validation | suites complètes, analyses et smokes Golden | **ACCEPT** |
| Critique finale | limites explicites, absence de débit anticipé, changements utilisateur isolés | **ACCEPT avec réserves documentées** |

Aucun sub-agent n’a été lancé : les cinq passes ont été conduites séparément
par l’agent principal, conformément à la restriction de collaboration active.

## 5. TDD et incidents de validation

### RED initial

Le premier test moteur ne compilait pas :

- paramètre nommé `targetPartyIndex` absent ;
- type `PsdkBattleReviveItemEffect` absent.

Après l’ouverture du catalogue UI, un test historique attendait encore
`antidote` désactivé. Il a été mis à jour pour refléter la nouvelle capacité.

Une exécution parallèle de deux commandes Flutter a rencontré une course sur
`build/native_assets/macos/objective_c.dylib`. La même commande, relancée
seule, a compilé et passé ; ce n’était pas une erreur produit.

La première suite runtime complète a trouvé une attente historique identique
dans `battle_command_menu_component_test.dart`. Après correction ciblée, ce
test a passé (+28) puis la suite complète a passé (+2192, 1 skip attendu).

## 6. Inventaire des fichiers

| Fichier | Rôle |
|---|---|
| `docs/superpowers/plans/2026-07-26-rm-023-generic-battle-items-v0.md` | plan d’implémentation et critères cochés |
| `packages/map_battle/lib/map_battle.dart` | export public de l’effet Revive |
| `packages/map_battle/lib/src/application/battle_session_facade.dart` | validation canonique des décisions item |
| `packages/map_battle/lib/src/application/battle_turn_runner.dart` | rejet atomique d’un item sans effet |
| `packages/map_battle/lib/src/domain/action/battle_action.dart` | effet Revive et cible party explicite |
| `packages/map_battle/lib/src/domain/action/battle_action_decision_mapper.dart` | propagation de targetPartyIndex |
| `packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart` | heal/cure/revive sur actif ou réserve |
| `packages/map_battle/lib/src/domain/decision/battle_decision.dart` | contrat item et taille de party dans la requête |
| `packages/map_battle/lib/src/domain/timeline/battle_timeline_event.dart` | partyIndex dans le reçu public |
| `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart` | remplacement cohérent party/slot actif |
| `packages/map_battle/lib/src/psdk/domain/psdk_battle_timeline.dart` | partyIndex dans l’événement PSDK |
| `packages/map_battle/test/generic_battle_items_v0_test.dart` | preuve moteur ciblée |
| `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart` | transaction runtime générique et débit post-reçu |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` | soumission générique et narration de cible réserve |
| `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart` | registre canonique des medicines supportées |
| `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart` | libellés no-code des cibles non compatibles |
| `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart` | ciblage selon heal/cure/revive |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | activation générique PSDK et réserves |
| `packages/map_runtime/test/battle_bag_menu_model_test.dart` | preuve de sélection antidote |
| `packages/map_runtime/test/battle_command_menu_component_test.dart` | preuve du sous-menu medicines |
| `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart` | preuves cibles statut et K.O. |
| `packages/map_runtime/test/battle_potion_apply_runtime_test.dart` | preuve potion réserve et compatibilité |
| `packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart` | preuve runtime antidote/revive/atomicité |
| `reports/gameplay/fg_050_generic_battle_items_v0.md` | présent Evidence Pack |

## 7. Zones de diff

- Contrat moteur : décision/action item, `targetPartyIndex`, taille de party.
- Résolution moteur : heal, cure, revive et rejet atomique sans effet.
- État/timeline : remplacement party + actif et reçu item avec `partyIndex`.
- Pont runtime : registre gameplay, mapping des statuts, reçu obligatoire,
  write-back puis consommation.
- Présentation : medicines supportées, réserves PSDK, motifs full HP/statut/K.O.
- Tests : caractérisation legacy mise à jour et nouvelles preuves ciblées.

Numstat avant ajout de ce rapport :

```text
map_battle: 188 insertions, 42 suppressions sur 10 fichiers suivis
map_runtime: 455 insertions, 99 suppressions sur 10 fichiers suivis
nouveaux tests: 190 lignes battle, 262 lignes runtime
plan: 52 lignes
```

## 8. Commandes et résultats exacts

| Commande | Résultat |
|---|---|
| `cd packages/map_battle && dart test test/generic_battle_items_v0_test.dart` | PASS — +5, All tests passed |
| `cd packages/map_runtime && flutter test test/runtime_generic_battle_items_v0_test.dart test/battle_potion_apply_runtime_test.dart test/battle_bag_menu_model_test.dart test/battle_medicine_target_menu_model_test.dart` | PASS — +41, All tests passed |
| `cd packages/map_runtime && flutter test test/battle_command_menu_component_test.dart` | PASS — +28, All tests passed |
| `cd packages/map_gameplay && dart test` | PASS — +400, All tests passed |
| `cd packages/map_gameplay && dart analyze` | PASS — No issues found |
| `cd packages/map_battle && dart test` | PASS — +1757, All tests passed |
| `cd packages/map_battle && dart analyze` | PASS — No issues found |
| `cd packages/map_runtime && flutter test --reporter compact` | PASS — +2192, 1 skipped test, All other tests passed |
| `cd packages/map_runtime && flutter analyze` | PASS — No issues found |
| `cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart` | PASS — +3, All tests passed |
| `cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart` | PASS — +1, All tests passed |
| `cd examples/playable_runtime_host && flutter analyze` | PASS — No issues found |
| `git diff --check` | PASS — aucune sortie |

## 9. Critères de fin RM-023 / FG-050

- [x] Décision item générique.
- [x] Cible de party explicite, actif ou réserve.
- [x] Soin PV.
- [x] Cure de statut compatible.
- [x] Revive à 50 %.
- [x] Refus sans tour/RNG/état muté lorsque l’objet n’a aucun effet.
- [x] Reçu moteur exact avant débit.
- [x] Write-back vers le slot runtime exact.
- [x] Bag débité d’une unité après acceptation seulement.
- [x] UI no-code adaptée au type d’effet.
- [x] Suites complètes et smokes verts.

## 10. Non-objectifs et risques résiduels

- La restauration de PP est volontairement reportée à **RM-041**.
- Les objets tenus et leurs hooks sont volontairement reportés à **RM-024**.
- Le fallback legacy non-PSDK ne sait toujours appliquer que les quatre soins
  PV historiques ; le chemin produit PSDK couvre heal/cure/revive.
- Les cures et Revive ont une preuve d’état et de reçu, mais pas encore une
  animation/narration dédiée aussi riche que celle des soins PV.
- Le V0 ne fournit pas de catalogue auteuré d’objets de dresseur.
- La topologie reste singles, bien que la cible de party ne soit plus limitée au
  combattant actif.

## 11. Auto-critique finale

La transaction est robuste sur l’invariant le plus important : aucun objet
runtime n’est débité avant acceptation canonique. Le reçu est typé et rattaché
à l’index de party exact, ce qui évite un succès overlay-only.

Le point le moins élégant reste le fichier historique
`runtime_battle_bag_hp_heal_item_apply.dart`, qui héberge désormais aussi le
chemin générique. Le renommer immédiatement aurait élargi inutilement le diff ;
un déplacement peut être envisagé dans un lot d’architecture ultérieur.

Le registre gameplay et le moteur PSDK portent deux représentations de statut.
Le mapping est exhaustif pour les six statuts majeurs supportés et analysé par
Dart, mais toute future extension devra maintenir ce pont.

## 12. Statut roadmap proposé

**FG-050 / RM-023 → DONE**, sur preuve fraîche de code, tests, analyses, smokes
et isolation Git. La roadmap canonique n’est pas modifiée par ce lot ; cette
mise à jour reste une proposition conformément aux règles du dépôt.

## 13. Contenu complet des fichiers créés

### `docs/superpowers/plans/2026-07-26-rm-023-generic-battle-items-v0.md`

```markdown
# RM-023 Generic Battle Items V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans and superpowers:test-driven-development.

**Goal:** Rendre utilisables en combat les medicines HP, cures de statut et
Revive via une décision PSDK générique, une cible de party explicite et une
consommation d'inventaire post-acceptation.

**Architecture:** `map_gameplay` reste le registre canonique des effets
d'items joueur. `map_battle` reçoit un effet résolu et l'applique à un index de
party explicite. `map_runtime` prévalide la cible, soumet la décision, exige un
événement `item_consumed`, puis seulement écrit le résultat et débite le bag.
L'overlay dérive ses cibles du type d'effet réel.

**Non-goals:** restauration de PP (`RM-041`), items tenus (`RM-024`), catalogue
de battle items auteuré par trainer.

---

### Task 1: Cible de party et Revive dans `map_battle`

- [x] Tests RED heal réserve, cure statut et revive.
- [x] Ajouter `targetPartyIndex` à la décision/action item.
- [x] Ajouter `PsdkBattleReviveItemEffect`.
- [x] Ajouter une mutation immuable cohérente party + slot actif.
- [x] Faire valider l'item par la façade canonique RM-022.

### Task 2: Transaction runtime générique

- [x] Tests RED sur antidote, full-heal, revive et rejet sans débit.
- [x] Résoudre l'effet depuis `PlayerItemEffectRegistry.mvp`.
- [x] Mapper statuts gameplay → PSDK.
- [x] Soumettre au moteur avant consommation.
- [x] Exiger l'événement consommé exact.
- [x] Écrire HP/statut sur les slots de party runtime puis consommer une unité.
- [x] Préserver le wrapper HP historique comme compatibilité.

### Task 3: UI de sélection honnête

- [x] Étendre le bag aux medicines heal/cure/revive supportées.
- [x] Rendre les cibles selon l'effet : blessé, statut compatible ou K.O.
- [x] Autoriser les réserves PSDK.
- [x] Ajouter les raisons désactivées no-code pertinentes.

### Task 4: Vérification

- [x] Tests/analyse `map_gameplay`, `map_battle`, `map_runtime`.
- [x] Suites complètes des packages modifiés.
- [x] Smoke Golden runtime.
- [x] Evidence Pack `FG-050`.
- [x] Commit isolé et état Git final.
```

### `packages/map_battle/test/generic_battle_items_v0_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('generic battle items v0', () {
    test('heals an explicit reserve party target', () {
      final session = _session(
        reserve: _combatant(id: 'reserve', hp: 20),
      );

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'potion',
          target: psdkPlayerSlot,
          targetPartyIndex: 1,
          effect: PsdkBattleHpHealItemEffect.flat(20),
          highPriority: true,
        ),
      );

      expect(
        result.state.psdkState.partyForBank(psdkPlayerSlot.bank)[1].currentHp,
        40,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(80));
      expect(
        result.timeline.events
            .whereType<BattleItemTimelineEvent>()
            .single
            .itemId,
        'potion',
      );
    });

    test('cures a compatible major status on an explicit target', () {
      final session = _session(
        playerStatus: PsdkBattleMajorStatus.poison,
      );

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'antidote',
          target: psdkPlayerSlot,
          targetPartyIndex: 0,
          effect: PsdkBattleStatusCureItemEffect.only(
            <PsdkBattleMajorStatus>{PsdkBattleMajorStatus.poison},
          ),
          highPriority: true,
        ),
      );

      expect(
        result.state.battlerAt(psdkPlayerSlot).majorStatus,
        isNull,
      );
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1),
      );
    });

    test('revives a fainted reserve to the requested HP percentage', () {
      final session = _session(
        reserve: _combatant(id: 'reserve', hp: 0),
      );

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'revive',
          target: psdkPlayerSlot,
          targetPartyIndex: 1,
          effect: PsdkBattleReviveItemEffect(percent: 50),
          highPriority: true,
        ),
      );

      expect(
        result.state.psdkState.partyForBank(psdkPlayerSlot.bank)[1].currentHp,
        40,
      );
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1),
      );
    });

    test('rejects an invalid item target before the turn mutates', () {
      final session = _session();

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'potion',
            target: psdkPlayerSlot,
            targetPartyIndex: 8,
            effect: PsdkBattleHpHealItemEffect.flat(20),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, 0);
    });

    test('rejects a no-effect item atomically', () {
      final session = _session(playerHp: 80);

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'potion',
            target: psdkPlayerSlot,
            targetPartyIndex: 0,
            effect: PsdkBattleHpHealItemEffect.flat(20),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, 0);
      expect(session.state.battlerAt(psdkPlayerSlot).currentHp, 80);
    });
  });
}

BattleSessionFacade _session({
  int playerHp = 80,
  PsdkBattleMajorStatus? playerStatus,
  PsdkBattleCombatantSetup? reserve,
}) {
  return BattleSessionFacade.fromPsdkSetup(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        hp: playerHp,
        status: playerStatus,
      ),
      playerReserves: <PsdkBattleCombatantSetup>[
        if (reserve != null) reserve,
      ],
      opponent: _combatant(id: 'opponent', hp: 80),
      isTrainerBattle: true,
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  PsdkBattleMajorStatus? status,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    majorStatus: status,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: '$id-move',
        dbSymbol: '$id-move',
        name: '$id-move',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 10,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
```

### `packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

void main() {
  group('runtime generic battle items v0', () {
    test('antidote clears a compatible status then consumes one item', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
          majorStatus: PsdkBattleMajorStatus.poison,
        ),
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: _gameState(
          itemId: 'antidote',
          members: <PlayerPokemon>[
            _partyMember(
              speciesId: 'sproutle',
              currentHp: 60,
              statusId: 'poison',
            ),
          ],
        ),
        context: _context(const <int>[0]),
        itemId: 'antidote',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      expect(result, isNotNull);
      expect(result!.effectKind.name, 'cureStatus');
      expect(result.updatedDisplaySession.state.player.majorStatus, isNull);
      expect(result.updatedGameState.party.members.single.statusId, isEmpty);
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(
        psdkSession.state.psdkState.battlerAt(psdkPlayerSlot).majorStatus,
        isNull,
      );
    });

    test('revive restores a fainted reserve and writes it back', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 60,
        ),
        playerReserves: <PsdkBattleCombatantSetup>[
          _combatant(
            id: 'player_1',
            speciesId: 'benchmon',
            currentHp: 0,
          ),
        ],
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: _gameState(
          itemId: 'revive',
          members: <PlayerPokemon>[
            _partyMember(speciesId: 'sproutle', currentHp: 60),
            _partyMember(speciesId: 'benchmon', currentHp: 0),
          ],
        ),
        context: _context(const <int>[0, 1]),
        itemId: 'revive',
        targetLineupIndex: 1,
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      expect(result, isNotNull);
      expect(result!.effectKind.name, 'revive');
      expect(result.appliedAmount, 40);
      expect(
        result.updatedDisplaySession.state.playerReserve.single.currentHp,
        40,
      );
      expect(result.updatedGameState.party.members[1].currentHp, 40);
      expect(result.updatedGameState.bag.entries, isEmpty);
      expect(
        psdkSession.state.psdkState
            .partyForBank(psdkPlayerSlot.bank)[1]
            .currentHp,
        40,
      );
    });

    test('a no-effect item leaves engine, party and bag unchanged', () {
      final psdkSession = _session(
        player: _combatant(
          id: 'player_0',
          speciesId: 'sproutle',
          currentHp: 80,
        ),
      );
      final displaySession = psdkSession.createLegacyDisplaySession(
        isTrainerBattle: true,
        trainerId: 'trainer',
      );
      final gameState = _gameState(
        itemId: 'antidote',
        members: <PlayerPokemon>[
          _partyMember(speciesId: 'sproutle', currentHp: 80),
        ],
      );

      final result = tryApplyRuntimePsdkBattleItemUse(
        psdkSession: psdkSession,
        displaySession: displaySession,
        gameState: gameState,
        context: _context(const <int>[0]),
        itemId: 'antidote',
        targetLineupIndex: 0,
        isTrainerBattle: true,
        trainerId: 'trainer',
      );

      expect(result, isNull);
      expect(psdkSession.state.turnNumber, 0);
      expect(gameState.party.members.single.currentHp, 80);
      expect(gameState.bag.entries.single.quantity, 1);
    });
  });
}

RuntimePsdkBattleSessionAdapter _session({
  required PsdkBattleCombatantSetup player,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singles(
      player: player,
      playerReserves: playerReserves,
      opponent: _combatant(
        id: 'opponent_0',
        speciesId: 'sparkitten',
        currentHp: 80,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 17,
        moveCritical: 23,
        moveAccuracy: 31,
        generic: 47,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required String speciesId,
  required int currentHp,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 20,
    maxHp: 80,
    currentHp: currentHp,
    majorStatus: majorStatus,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: '$id-wait',
        dbSymbol: '$id-wait',
        name: 'Wait',
        type: 'normal',
        category: PsdkBattleMoveCategory.status,
        power: 0,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.user,
      ),
    ],
  );
}

GameState _gameState({
  required String itemId,
  required List<PlayerPokemon> members,
}) {
  return GameState(
    saveId: 'generic-battle-items-v0',
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: itemId, categoryId: 'medicine', quantity: 1),
      ],
    ),
    party: PlayerParty(members: members),
  );
}

PlayerPokemon _partyMember({
  required String speciesId,
  required int currentHp,
  String statusId = '',
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'pressure',
    level: 20,
    knownMoveIds: const <String>['wait'],
    currentHp: currentHp,
    statusId: statusId,
  );
}

RuntimeActiveBattleContext _context(List<int> lineupPartyIndices) {
  return RuntimeActiveBattleContext.withLineupMapping(
    request: const TrainerBattleStartRequest(
      requestId: 'trainer-request',
      createdAtEpochMs: 1,
      returnContext: OverworldReturnContext(
        mapId: 'field_map',
        playerPos: GridPos(x: 1, y: 1),
        playerFacing: Direction.north,
      ),
      trainerId: 'trainer',
      npcEntityId: 'npc_trainer',
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
    ),
    playerPartyIndex: lineupPartyIndices.first,
    playerPartySlotIndicesByLineupIndex: lineupPartyIndices,
  );
}
```

## 14. État Git final attendu avant commit

Les fichiers RM-023 listés ci-dessus doivent être stagés explicitement. Les sept
changements utilisateur initiaux doivent rester hors index. Après commit, le
working tree doit encore afficher uniquement ces sept changements utilisateur.
