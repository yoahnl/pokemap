# RM-029 — Exhausted PP & Struggle V0

## Résumé exécutif

**Lot exact :** `RM-029 — Exhausted PP & Struggle V0`

**Liens canoniques :** `FG-041`, `FG-052`, `FG-053`

**Verdict proposé :** `DONE`

Le moteur PSDK canonique ne termine plus sur `noLegalChoice` lorsque le
Pokémon actif possède des moves mais qu’aucun n’est légalement sélectionnable.
Il expose et exécute désormais un fallback Struggle synthétique :

- puissance 50 ;
- physique ;
- typeless via le type neutre `unknown` ;
- précision always-hit ;
- priorité 0 ;
- recul égal à 1/4 des PV max du lanceur ;
- aucun PP consommé ou persisté ;
- aucune insertion dans le moveset ou le write-back.

Le même contrat est consommé par l’IA adverse. Côté joueur, le bridge runtime
ajoute Struggle uniquement à la projection legacy utilisée par le menu, puis
retraduit ce choix vers la décision PSDK canonique. L’écran affiche donc
`FIGHT → Struggle` au lieu d’un menu vide.

## Confirmation du scope

### Inclus

- définition battle unique de Struggle V0 ;
- décision `BattleDecision.struggle()` portée par le contrat Fight existant ;
- signal explicite `BattleEngineDecisionRequest.canStruggle` ;
- fallback quand tous les PP sont épuisés ;
- fallback quand des PP existent mais que tous les moves sont bloqués ;
- exécution joueur et IA ;
- dégâts, always-hit et recul 1/4 PV max ;
- coexistence avec switch/capture/fuite/item ;
- bridge de présentation runtime ;
- protection du moveset, des PP et du write-back ;
- documentation de l’état canonique.

### Volontairement hors scope

- port de Struggle dans le moteur legacy direct `BattleSession` ;
- ajout de Struggle aux données projet ou aux movesets sauvegardés ;
- authoring editor ;
- modification de la policy de switch/item/fuite trainer ;
- traitement d’un combattant malformé sans aucun move ;
- promotion de la gate complète, réservée à RM-053.

## Policy V0

| Axe | Décision |
|---|---|
| ID | `struggle` |
| Nom | `Struggle` |
| Catégorie | physique |
| Puissance | 50 |
| Type | typeless, représenté par `unknown` pour neutralité sans STAB |
| Précision | `0` PSDK, sentinelle always-hit |
| Priorité | 0 |
| Cible | adversaire adjacent |
| Contact | oui |
| Recul | 1/4 des PV max |
| PP synthétique | 1 uniquement dans la projection UI legacy |
| PP canonique consommé | aucun |
| Write-back | jamais |

## Audit initial

### État observé

- `BattleEngineDecisionRequest.fromContext` retirait les moves sans PP ou
  bloqués de `fightChoices`.
- sans switch, capture ou fuite, la request devenait `noLegalChoice`.
- `PsdkBattleAi` retournait `BattleDecision.noAction()` quand aucun move
  n’était utilisable.
- le runner et le registry possédaient déjà le comportement `s_struggle`,
  dont le recul 1/4 PV max.
- Rock Head, Choice items, Encore, Torment et les familles copy/call
  reconnaissaient déjà l’ID `struggle`.
- aucun contrat ne synthétisait réellement cette attaque.
- le runtime utilisait un `BattleSession` legacy comme projection d’affichage,
  même lorsque l’exécution réelle passait par PSDK.

### Risques identifiés

- ajouter Struggle au moveset réel et le sauvegarder par erreur ;
- détourner un slot move réel ou consommer ses PP ;
- permettre Struggle alors qu’un move légal existe ;
- masquer un setup malformé avec zéro move configuré ;
- perdre les choix switch/item/capture/fuite ;
- laisser l’IA adverse sur `noAction` ;
- faire crasher la projection legacy sur le slot synthétique ;
- surpromouvoir le moteur legacy direct ou `FG-053`.

### Décisions d’architecture

- le slot interne réservé est `-1`, impossible à confondre avec `0..n-1` ;
- `BattleDecision.struggle()` reste une spécialisation de
  `BattleFightDecision`, afin de préserver le contrat canonique unifié ;
- le runner utilise la donnée synthétique de l’action et saute toute mutation
  PP/moveset ;
- la façade et `BattleEngine.submit` rejettent Struggle si `canStruggle` est
  faux ;
- un combattant sans aucun move reste fail-closed sur `noLegalChoice` ;
- le runtime ajoute une ligne Struggle uniquement à son snapshot
  d’affichage, jamais à l’état PSDK.

## Verdict des cinq passes obligatoires

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / Architecture | PASS | réutilisation de `s_struggle`, aucune donnée projet inventée |
| Implémentation | PASS | request, runner, IA et bridge runtime raccordés |
| Tests | PASS après mise à jour de deux preuves obsolètes | battle 1764/1764 ; runtime 2204/2204, 1 skip historique |
| Build / Validation | PASS | analyses battle/runtime sans diagnostic ; smoke inclus |
| Critique finale | PASS avec limite déclarée | moteur legacy direct non promu, zéro-move fail-closed |

Ces passes ont été conduites comme cinq revues nommées et séparées dans le même
agent. Aucun sub-agent n’a été lancé, conformément à la contrainte active
interdisant la délégation proactive.

## Inventaire exhaustif

### Fichiers modifiés

| Fichier | Zone précise | Raison et impact |
|---|---|---|
| `docs/combat/battle-canonical-state-v3.1.md` | section fragilités | décrit la nouvelle vérité PSDK/runtime et la limite legacy |
| `packages/map_battle/lib/map_battle.dart` | barrel public | exporte le contrat Struggle |
| `packages/map_battle/lib/src/application/battle_engine.dart` | `submit` | rejette une synthèse Struggle illégale |
| `packages/map_battle/lib/src/application/battle_turn_runner.dart` | résolution fight + IA par défaut | exécute le move synthétique sans PP/write-back |
| `packages/map_battle/lib/src/domain/action/battle_action_decision_mapper.dart` | mapping Fight | construit l’action Struggle au slot réservé |
| `packages/map_battle/lib/src/domain/ai/psdk_battle_ai.dart` | fallback de décision | remplace `noAction` par Struggle si le moveset existe |
| `packages/map_battle/lib/src/domain/decision/battle_decision.dart` | décision et request | ajoute le factory, `isStruggle` et `canStruggle` |
| `packages/map_battle/test/psdk_item_choice_lock_test.dart` | cas Choice + Disable | remplace l’ancien attendu `noLegalChoice` |
| `packages/map_battle/test/psdk_pp_history_test.dart` | dernier PP consommé | attend désormais Struggle |
| `packages/map_battle/test/unified_battle_decision_contract_test.dart` | contrat épuisement PP | prouve le fallback RM-029 |
| `packages/map_runtime/lib/src/application/runtime_psdk_battle_session_adapter.dart` | choix, display setup, turn projection | expose puis soumet Struggle sans mutation réelle |
| `packages/map_runtime/test/runtime_psdk_battle_decision_contract_test.dart` | scénario PP épuisés | prouve menu, exécution et write-back |

### Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_battle/lib/src/domain/move/battle_struggle.dart` | définition synthétique legacy/PSDK |
| `packages/map_battle/test/struggle_policy_v0_test.dart` | preuve dédiée joueur, IA, recul et garde-fous |
| `docs/superpowers/plans/2026-07-27-rm-029-exhausted-pp-struggle-v0.md` | plan d’implémentation exécuté |
| `reports/gameplay/fg_041_052_053_exhausted_pp_struggle_v0.md` | présent Evidence Pack |

Le présent rapport n’est pas reproduit dans lui-même afin d’éviter une
récursion infinie. Les trois autres fichiers créés sont reproduits
intégralement en annexe.

## Découpage précis des modifications

### Request et décision

- `BattleDecision.struggle()` crée un `BattleFightDecision` au slot `-1`.
- `BattleFightDecision.isStruggle` rend le sens observable sans second
  vocabulaire d’action.
- `canStruggle` vaut vrai uniquement si :
  - l’actif n’est pas K.O. ;
  - son moveset n’est pas vide ;
  - aucun move n’est légalement sélectionnable.
- le fallback s’ajoute à `allowedDecisions` sans supprimer les switches,
  captures ou fuites.
- `noLegalChoice` reste utilisé pour un moveset vide malformé.

### Exécution

- le mapper crée `createCanonicalPsdkStruggleMove()` au slot interne `-1` ;
- le runner reconnaît cette paire slot/ID et utilise la donnée d’action ;
- le chemin `spendPp` et `replaceMoveAt` est sauté ;
- le comportement existant `s_struggle` produit les dégâts et le recul ;
- move history et timeline enregistrent `struggle` ;
- aucun `BattleMovePpSpentTimelineEvent` n’est produit pour Struggle.

### IA

- l’IA conserve l’ordre item, switch puis fuite ;
- si aucune de ces actions n’est retenue et qu’aucun move n’est utilisable,
  elle choisit Struggle ;
- si le moveset est vide, elle conserve `noAction` fail-closed ;
- le fallback sans IA choisit le premier move avec PP, sinon Struggle.

### Runtime/UI

- la projection `BattleCombatantData` du joueur reçoit une ligne Struggle
  uniquement quand la request PSDK l’autorise ;
- le PP synthétique de présentation vaut 1 pour rendre la ligne sélectionnable
  dans le menu legacy ;
- l’index de cette ligne est reconverti en `BattleDecision.struggle()` ;
- la projection du tour utilise `canonicalLegacyStruggleMove` sans indexer le
  moveset PSDK ;
- l’état PSDK et `writeBackMoves` restent strictement inchangés.

## Tests positifs et négatifs

### Positifs

- PP à zéro => `turnChoice` + `canStruggle` ;
- Struggle inflige des dégâts et 20 PV de recul pour 80 PV max ;
- Taunt bloquant le seul move de statut => Struggle ;
- Struggle coexiste avec un switch volontaire ;
- l’IA adverse épuisée utilise Struggle ;
- le menu runtime affiche `Struggle` et `Power 50` ;
- le display turn restitue une vraie `BattleActionFight` Struggle ;
- les suites complètes et le smoke restent verts.

### Négatifs et garde-fous

- un move avec PP légal => Struggle refusé atomiquement ;
- moveset vide => `noLegalChoice`, pas de fallback inventé ;
- aucun événement de dépense PP Struggle ;
- aucun move Struggle dans l’état réel ni `writeBackMoves` ;
- forced replacement reste indépendant du fallback ;
- Choice + Disable ne produit plus le dead-end historique.

## Commandes et résultats exacts

### RED initial

```bash
cd packages/map_battle
dart test \
  test/struggle_policy_v0_test.dart \
  test/unified_battle_decision_contract_test.dart
```

```text
Échec de compilation attendu :
- constructeur BattleDecision.struggle absent ;
- canStruggle et isStruggle absents ;
- canonicalStruggleMoveId absent.
```

```bash
cd packages/map_runtime
flutter test test/runtime_psdk_battle_decision_contract_test.dart
```

```text
Échec de compilation attendu :
- canStruggle absent ;
- canonicalStruggleMoveId absent.
```

### Tests dédiés après implémentation

```bash
cd packages/map_battle
dart test \
  test/struggle_policy_v0_test.dart \
  test/unified_battle_decision_contract_test.dart
```

```text
+12: All tests passed!
```

```bash
cd packages/map_runtime
flutter test test/runtime_psdk_battle_decision_contract_test.dart
```

```text
+4: All tests passed!
```

### Preuves élargies battle

```bash
cd packages/map_battle
dart test \
  test/struggle_policy_v0_test.dart \
  test/unified_battle_decision_contract_test.dart \
  test/psdk_ai_action_selection_test.dart \
  test/psdk_ai_difficulty_policy_test.dart \
  test/psdk_ai_move_scoring_test.dart \
  test/psdk_move_families/move_prevention_test.dart \
  test/psdk_move_families/recoil_move_behavior_test.dart \
  test/psdk_action_queue_test.dart
```

```text
+65: All tests passed!
```

### Preuves élargies runtime et smoke

```bash
cd packages/map_runtime
flutter test \
  test/runtime_psdk_battle_decision_contract_test.dart \
  test/runtime_psdk_battle_session_adapter_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

```text
+100: All tests passed!
```

### Incident de première suite complète

La première suite battle complète a révélé deux anciens attendus
`noLegalChoice`, directement remplacés par RM-029 :

```text
test/psdk_item_choice_lock_test.dart:
Expected noLegalChoice, actual turnChoice.

test/psdk_pp_history_test.dart:
Expected noLegalChoice, actual turnChoice.
```

Les deux tests ont été renommés/alignés sur `canStruggle`, puis rejoués :

```bash
cd packages/map_battle
dart test \
  test/psdk_item_choice_lock_test.dart \
  test/psdk_pp_history_test.dart
```

```text
+8: All tests passed!
```

### Suites complètes finales

```bash
cd packages/map_battle
dart test --concurrency=4
dart analyze
```

```text
+1764: All tests passed!
Analyzing map_battle... No issues found!
```

```bash
cd packages/map_runtime
flutter test --concurrency=4
flutter analyze
```

```text
+2204 ~1: All tests passed!
Analyzing map_runtime... No issues found! (ran in 4.9s)
```

Le skip préexistant est
`selbrume_asset_integrity_contract_test.dart`, explicitement marqué
« Superseded by the active port_reference_v3 contract above. ».

### Format et hygiene

```bash
dart format <13 fichiers Dart du lot>
git diff --check
```

```text
Formatted 13 files (0 changed) in 0.04 seconds.
git diff --check: aucune sortie, code 0.
```

## État Git

### État initial

Base RM-028 :

```text
21df6bd5c feat(battle): apply nature iv ev fidelity
```

Modifications utilisateur préexistantes et protégées :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

### Isolation de commit

Seuls les fichiers listés dans l’inventaire RM-029 sont inclus. Les sept
fichiers utilisateur préexistants sont exclus du staging.

### État final attendu

Après commit, le worktree doit contenir exactement les sept modifications
utilisateur préexistantes. Cette preuve est contrôlée après création du commit.

## Statuts de roadmap proposés

| ID | Statut proposé | Justification |
|---|---|---|
| `RM-029` | `DONE` | fallback joueur/IA, runtime UI et write-back prouvés |
| `FG-041` | reste `DONE` | les PP réels restent persistés, Struggle n’en invente aucun |
| `FG-052` | `PARTIAL` proposé | le dead-end PP est fermé ; le lot canonique couvre aussi le remplacement mais la roadmap n’est pas modifiée ici |
| `FG-053` | reste `TODO` | la promotion appartient à RM-053 |

La roadmap canonique n’est pas modifiée dans ce lot.

## Auto-critique finale

### Points solides

- le comportement PSDK préexistant est réutilisé ;
- aucune donnée projet, move ou PP artificiel n’est persisté ;
- joueur et IA partagent la même définition ;
- les effets de prévention sont couverts ;
- les choix alternatifs restent disponibles ;
- l’UI réelle ne tombe plus sur le dead-end ;
- deux suites complètes et deux analyses sont vertes.

### Risques et limites restantes

- le moteur legacy direct conserve son ancien `noLegalChoice` ;
- `unknown` est le seam typeless existant ; une future taxonomie de type
  explicite pourrait le remplacer ;
- la projection UI utilise 1 PP synthétique, volontairement non canonique et
  strictement confinée au display ;
- un combattant sans aucun move reste bloqué, car RM-029 ne doit pas masquer
  une configuration invalide ;
- les doubles et le targeting riche restent hors scope ;
- la capability n’est pas promue avant RM-053.

### Prochain lot recommandé

`RM-053 — Full Battle Capability Gate`, pour promouvoir ensemble held items,
nature/IV/EV et Struggle sans modifier le cutline MVP RM-026.

## Annexe A — `battle_struggle.dart` complet

```dart
import '../../battle_move.dart';
import '../../battle_setup.dart';
import '../../psdk/domain/psdk_battle_move.dart';

const canonicalStruggleMoveId = 'struggle';
const canonicalStruggleMoveName = 'Struggle';

/// Reserved action slot used only while executing the synthetic fallback.
///
/// Real moves always keep their authored `0..n-1` slots. This value must never
/// be written back to a party member or exposed as an authored move index.
const canonicalStruggleMoveSlot = -1;

/// Legacy presentation projection used by the runtime command menu.
///
/// The one synthetic PP makes the existing read-only legacy menu consider the
/// row selectable. The canonical PSDK runner never spends or persists it.
const canonicalLegacyStruggleMoveData = BattleMoveData(
  id: canonicalStruggleMoveId,
  name: canonicalStruggleMoveName,
  power: 50,
  type: 'unknown',
  category: BattleMoveCategory.physical,
  target: BattleMoveTarget.opponent,
  accuracy: BattleMoveAccuracy.alwaysHits(),
  pp: 1,
  currentPp: 1,
);

const canonicalLegacyStruggleMove = BattleMove(
  id: canonicalStruggleMoveId,
  name: canonicalStruggleMoveName,
  power: 50,
  type: 'unknown',
  category: BattleMoveCategory.physical,
  target: BattleMoveTarget.opponent,
  accuracy: BattleMoveAccuracy.alwaysHits(),
  pp: 1,
  currentPp: 1,
);

/// Gen-4+-style PokeMap V0 fallback: typeless power 50, always hit, 1/4 max-HP
/// recoil through the existing `s_struggle` behavior.
PsdkBattleMoveData createCanonicalPsdkStruggleMove() {
  return PsdkBattleMoveData(
    id: canonicalStruggleMoveId,
    dbSymbol: canonicalStruggleMoveId,
    name: canonicalStruggleMoveName,
    type: 'unknown',
    category: PsdkBattleMoveCategory.physical,
    power: 50,
    accuracy: 0,
    pp: 1,
    currentPp: 1,
    priority: 0,
    battleEngineMethod: 's_struggle',
    target: PsdkBattleMoveTarget.adjacentFoe,
    contact: true,
  );
}
```

## Annexe B — `struggle_policy_v0_test.dart` complet

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/taunt_effect.dart';
import 'package:test/test.dart';

void main() {
  group('RM-029 Struggle policy V0', () {
    test('exhausted PP exposes Struggle instead of noLegalChoice', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.kind, BattleEngineDecisionRequestKind.turnChoice);
      expect(request.fightChoices, isEmpty);
      expect(request.canStruggle, isTrue);
      expect(
        request.allowedDecisions,
        contains(
          isA<BattleFightDecision>().having(
            (decision) => decision.isStruggle,
            'isStruggle',
            isTrue,
          ),
        ),
      );
      expect(request.allows(const BattleDecision.struggle()), isTrue);
    });

    test('Struggle deals damage, recoils 1/4 max HP and consumes no PP', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
        ),
      );

      final result = session.submit(const BattleDecision.struggle());
      final struggleDamage = result.timeline.events
          .whereType<BattleDamageTimelineEvent>()
          .where((event) => event.moveId == canonicalStruggleMoveId)
          .toList(growable: false);
      final recoil = struggleDamage.singleWhere(
        (event) =>
            event.user.bank == psdkPlayerSlot.bank &&
            event.target.bank == psdkPlayerSlot.bank,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(struggleDamage, hasLength(2));
      expect(recoil.damage, 20);
      expect(player.moves.single.id, 'empty');
      expect(player.moves.single.currentPp, 0);
      expect(player.moves, isNot(contains(canonicalStruggleMoveId)));
      expect(
        player.writeBackMoves.map((move) => move.id),
        isNot(contains(canonicalStruggleMoveId)),
      );
      expect(
        result.timeline.events
            .whereType<BattleMovePpSpentTimelineEvent>()
            .where((event) => event.moveId == canonicalStruggleMoveId),
        isEmpty,
      );
    });

    test('a usable move keeps Struggle unavailable and rejection atomic', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'usable', currentPp: 1),
          ],
        ),
      );
      final before = session.state;

      expect(session.decisionRequest.canStruggle, isFalse);
      expect(
        session.decisionRequest.allows(const BattleDecision.struggle()),
        isFalse,
      );
      expect(
        () => session.submit(const BattleDecision.struggle()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, before.turnNumber);
      expect(
        session.state.battlerAt(psdkPlayerSlot).currentHp,
        before.battlerAt(psdkPlayerSlot).currentHp,
      );
    });

    test('Struggle coexists with a voluntary switch', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'empty', currentPp: 0),
          ],
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'reserve',
              moves: <PsdkBattleMoveData>[_move(id: 'reserve-hit')],
            ),
          ],
        ),
      );

      final request = session.decisionRequest;

      expect(request.canStruggle, isTrue);
      expect(request.switchChoices, hasLength(1));
      expect(
        request.allowedDecisions.whereType<BattleSwitchDecision>(),
        hasLength(1),
      );
    });

    test('all PP-positive moves prevented by effects also expose Struggle', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            TauntEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'status-only',
              power: 0,
              category: PsdkBattleMoveCategory.status,
              battleEngineMethod: 's_status',
            ),
          ],
        ),
      );

      expect(session.decisionRequest.fightChoices, isEmpty);
      expect(session.decisionRequest.canStruggle, isTrue);
      expect(
        session.submit(const BattleDecision.struggle()).timeline.events.where(
              (event) =>
                  event is BattleMoveDeclaredTimelineEvent &&
                  event.moveId == canonicalStruggleMoveId,
            ),
        isNotEmpty,
      );
    });

    test('a combatant with no configured move stays fail-closed', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(playerMoves: const <PsdkBattleMoveData>[]),
      );

      expect(
        session.decisionRequest.kind,
        BattleEngineDecisionRequestKind.noLegalChoice,
      );
      expect(session.decisionRequest.canStruggle, isFalse);
      expect(session.decisionRequest.allowedDecisions, isEmpty);
    });

    test('an exhausted opponent uses Struggle instead of noAction', () {
      final session = BattleSessionFacade.fromSetup(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(id: 'player-tap', power: 1),
          ],
          opponentMoves: <PsdkBattleMoveData>[
            _move(id: 'enemy-empty', currentPp: 0),
          ],
        ),
        opponentAi: const PsdkBattleAi(level: 1),
      );

      final result = session.submit(
        const BattleDecision.fight(moveSlot: 0),
      );
      final enemyStruggleDeclarations = result.timeline.events
          .whereType<BattleMoveDeclaredTimelineEvent>()
          .where(
            (event) =>
                event.user.bank == psdkOpponentSlot.bank &&
                event.moveId == canonicalStruggleMoveId,
          );
      final enemyRecoil = result.timeline.events
          .whereType<BattleDamageTimelineEvent>()
          .singleWhere(
            (event) =>
                event.moveId == canonicalStruggleMoveId &&
                event.user.bank == psdkOpponentSlot.bank &&
                event.target.bank == psdkOpponentSlot.bank,
          );

      expect(enemyStruggleDeclarations, hasLength(1));
      expect(enemyRecoil.damage, 20);
      expect(
        result.state.battlerAt(psdkOpponentSlot).moves.map((move) => move.id),
        <String>['enemy-empty'],
      );
    });
  });
}

BattleEngineSetup _setup({
  List<PsdkBattleMoveData>? playerMoves,
  List<PsdkBattleMoveData>? opponentMoves,
  PsdkBattleEffectStack? playerEffects,
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      moves: playerMoves ?? <PsdkBattleMoveData>[_move(id: 'player-hit')],
      effects: playerEffects,
    ),
    playerReserves: playerReserves,
    opponent: _combatant(
      id: 'opponent',
      moves: opponentMoves ?? <PsdkBattleMoveData>[_move(id: 'opponent-hit')],
    ),
    isTrainerBattle: true,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required List<PsdkBattleMoveData> moves,
  PsdkBattleEffectStack? effects,
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
    moves: moves,
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  int power = 40,
  int currentPp = 10,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 10,
    currentPp: currentPp,
    priority: 0,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
```

## Annexe C — plan RM-029 complet

```markdown
# RM-029 Exhausted PP & Struggle V0 Implementation Plan

**Goal:** remplacer le dead-end `noLegalChoice` par un Struggle canonique
lorsque le Pokémon actif possède des moves mais qu’aucun n’est légalement
sélectionnable.

**Architecture:** `map_battle` possède la définition synthétique et la décision
canonique Struggle. Le moteur PSDK exécute cette attaque sans l’ajouter au
moveset ni consommer/persister de PP. `map_runtime` adapte ce choix synthétique
vers le menu legacy d’affichage, puis le soumet au moteur canonique.

**Policy V0:** puissance 50, physique, typeless via `unknown`, précision
always-hit, priorité 0, cible adverse, recul égal à 1/4 des PV max, aucun PP
persisté.

**Non-goals:** modifier les movesets sauvegardés, porter Struggle dans le moteur
legacy direct, ajouter une UI editor, changer la policy de switch trainer ou
promouvoir RM-053.

### Task 1: Contrat battle canonique

- [x] Définir la donnée Struggle synthétique et son slot interne réservé.
- [x] Exposer Struggle seulement si des moves existent et qu’aucun n’est légal.
- [x] Préserver switch, item, capture et fuite comme autres choix légaux.
- [x] Garder les états K.O./remplacement hors du fallback Struggle.

### Task 2: Exécution PSDK

- [x] Mapper la décision Struggle vers une action synthétique.
- [x] Exécuter dégâts, always-hit et recul 1/4 PV max.
- [x] Ne consommer aucun PP et ne jamais ajouter Struggle au write-back.
- [x] Donner le même fallback à l’IA lorsqu’elle ne peut ni agir autrement ni switcher.

### Task 3: Bridge et surface runtime

- [x] Ajouter Struggle uniquement au moveset de présentation legacy.
- [x] Mapper le choix de présentation vers la décision canonique.
- [x] Afficher FIGHT/Struggle au lieu d’un dead-end.
- [x] Préserver le moveset et les PP réels après le tour.

### Task 4: Validation et clôture

- [x] Tests battle positifs, négatifs, joueur, IA et recul.
- [x] Tests runtime adapter/menu/write-back.
- [x] Suites package-scoped, analyses et smoke battle.
- [x] Evidence Pack FG-041/052/053 et commit isolé.
```
