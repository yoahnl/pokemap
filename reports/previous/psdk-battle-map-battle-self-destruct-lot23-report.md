# Lot 23 - PSDK SelfDestruct / Explosion

## Resume executif

Ce lot porte `s_explosion` depuis Pokemon SDK vers le moteur Dart clean architecture de `packages/map_battle`.

Le comportement implemente est volontairement limite a `SelfDestruct` / `Explosion` :

- degats normaux sur la cible via le pipeline Basic ;
- self-KO du lanceur avec ses PV courants apres un hit reussi ;
- self-KO aussi si la cible est immunisee ou protegee, avec `animation_cue` comme dans le chemin PSDK `on_move_failure(:immunity)` ;
- aucun self-KO sur miss precision ;
- aucun self-KO si les PP bloquent l'execution ;
- ordre PSDK conserve: degats cible, effets secondaires, puis self-KO.

Le lot corrige aussi l'extracteur PSDK : il reconnait maintenant les enregistrements Ruby non prefixes `register(:s_..., Klass)`, ce qui rend visibles `s_explosion` et 13 autres methodes qui etaient absentes de la matrice.

## Scope confirme

Inclus :

- `s_explosion` en statut `partial`.
- Scenario CLI `explosion` / `self_destruct`.
- Test de l'extracteur pour `register(:s_explosion, SelfDestruct)`.
- Regeneration de `psdk_move_registry_manifest.dart` et `reports/psdk-move-porting-matrix.md`.

Exclus volontairement :

- `s_misty_explosion` : laisse `missing` parce que son bonus depend du terrain Misty, absent de l'etat PSDK Dart actuel.
- `Damp` : absent parce que `PsdkBattleCombatantSetup` ne transporte pas encore d'ability.
- Explosion multi-cible : le lane PSDK Dart actuel ne supporte que `adjacentFoe` / `user` dans `PsdkBattleMoveTarget`.
- Les messages PSDK exacts et le process complet de faint callbacks.

## Remise en cause du scope

Instruction potentiellement risquee : porter `MistyExplosion` en meme temps que `Explosion`.

Pourquoi c'est un probleme :

- Pokemon SDK definit `MistyExplosion < SelfDestruct`, mais ajoute `real_base_power` avec `field_terrain_effect.misty?`.
- L'etat PSDK Dart actuel n'expose pas de terrain consommable par les moves.
- Le porter maintenant aurait produit soit une Explosion identique mais faussement marquee, soit un multiplicateur non testable.

Alternative appliquee :

- `s_explosion` est porte.
- `s_misty_explosion` devient visible dans le manifest grace au correctif d'extraction, mais reste `missing`.

## Audit initial

Sources PSDK auditees :

- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 SelfDestruct.rb`
  - `move_usable_by_user` echoue si un battler vivant a `:damp`.
  - `on_move_failure` ne self-KO que pour `:immunity`.
  - `deal_effect` inflige `user.hp` au user.
  - registre Ruby : `register(:s_explosion, SelfDestruct)`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 TerrainDamageMoves.rb`
  - `MistyExplosion < SelfDestruct`.
  - bonus de puissance uniquement si terrain Misty.
  - registre Ruby : `register(:s_misty_explosion, MistyExplosion)`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`
  - `BasicWithSuccessfulEffect` garde `effect_working?` vrai.
- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`
  - ordre du pipeline : `deal_damage`, `effect_working?`, `deal_status`, `deal_stats`, `deal_effect`.

Contrats Dart existants :

- `BattleMoveBehavior` execute les familles de moves via `createStaticBasicMoveRegistry`.
- `prepareBattleMove` centralise declaration, accuracy, Protect et immunite.
- `applyDirectDamage` clamp les degats aux PV courants et emet `PsdkBattleDamageEvent`.
- `BattleMoveSecondaryEffectResolver` applique les statuts/stages apres les degats.
- Le CLI `PsdkBattleCli` fournit les scenarios smoke deterministes.

Risques identifies :

- L'ancien extracteur ne capturait que `Move.register(...)`, donc `s_explosion` et `s_misty_explosion` etaient invisibles.
- Ne pas differencier miss et immunite aurait casse la semantique PSDK : SelfDestruct ne self-KO pas sur miss.
- Marquer `s_explosion` `ported` serait faux tant que `Damp` n'existe pas.

## Etat git initial

Le worktree etait deja sale avant ce lot, avec de nombreux fichiers modifies/non suivis issus des lots precedents, notamment tout le lane `packages/map_battle` non suivi par Git et des modifications `map_core` / `map_editor`.

Je n'ai pas nettoye ni revert ces changements.

## Fichiers modifies / crees

### `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`

Statut : cree.

Zones :

- `SelfDestructMoveBehavior.explosion`.
- `_shouldSelfKoAfterFailure`.
- `_selfKoUser`.

Raison :

- Porter la classe PSDK `SelfDestruct` pour `s_explosion`.

Impact :

- `s_explosion` devient executable dans le registre de moves PSDK Dart.
- Le self-KO utilise les PV courants, pas les PV max.
- `Damp` reste hors scope et justifie le statut `partial`.

### `packages/map_battle/test/psdk_move_families/self_destruct_move_behavior_test.dart`

Statut : cree.

Couverture :

- hit reussi ;
- miss precision ;
- immunite Ghost ;
- Protect ;
- PP vide ;
- ordre effets secondaires avant self-KO.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Zones modifiees :

- import de `self_destruct_move_behavior.dart` ;
- ajout de `const SelfDestructMoveBehavior.explosion()` dans `createStaticBasicMoveRegistry`.

Raison :

- Brancher `s_explosion` dans le registre statique clean PSDK.

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones modifiees :

- regex `_registerPattern` :
  - avant : `Move.register(:method, Klass)` seulement ;
  - apres : `(?:Move\.)?register(:s_method, Klass)`.
- ajout de `s_explosion` dans `_knownDartBehaviors`.

Raison :

- Pokemon SDK utilise des `register(:s_..., Klass)` non prefixes dans plusieurs fichiers de definitions.
- Le filtre `s_` evite de capturer des registres non-move comme `register(:regular_ground, ...)`.

Impact :

- Total matrice moves : 330 methodes.
- `s_explosion` devient `partial`.
- `s_misty_explosion` et les autres registres non prefixes deviennent visibles mais restent `missing`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Statut : regenere.

Ajouts visibles :

- `s_explosion` -> `SelfDestructMoveBehavior.explosion`, `partial`.
- `s_misty_explosion` -> `TODO`, `missing`.
- 12 autres registres non prefixes deviennent visibles en `missing`.

### `reports/psdk-move-porting-matrix.md`

Statut : regenere.

Resultat :

- Total registered methods: 330.
- `ported`: 19.
- `partial`: 23.
- `missing`: 288.

### `reports/psdk-effect-porting-matrix.md`

Statut : commande de regeneration lancee.

Impact attendu :

- Aucun changement fonctionnel lie a ce lot ; la commande a ete relancee pour garder la matrice d'extraction coherente.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Zones modifiees :

- help text `--scenario`.
- enum `_PsdkBattleCliScenario.explosion`.
- parser `explosion`, `self_destruct`, `self-destruct`.
- config scenario deterministe `explosion`.

Raison :

- Fournir un smoke test CLI directement utilisable par agents et humains.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Zones modifiees :

- test manifest Lot 23 :
  - `s_explosion` `partial`;
  - `s_misty_explosion` `missing`.
- test extracteur :
  - capture `register(:s_explosion, SelfDestruct)`;
  - ignore `register(:regular_ground, ...)`.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Zones modifiees :

- test scenario `explosion`.

Attendus :

- outcome `defeat`;
- `playerHp=0`;
- `opponentHp=92`;
- deux evenements `damage` pour `explosion`;
- `battle_ended` `defeat`.

## Tests crees ou modifies

Nouveau :

- `test/psdk_move_families/self_destruct_move_behavior_test.dart`

Modifies :

- `test/psdk_registry_manifest_test.dart`
- `test/psdk_battle_cli_test.dart`

## Cycle rouge / vert

Rouge observe avant implementation :

- `dart test test/psdk_move_families/self_destruct_move_behavior_test.dart`
  - echec attendu : `Unsupported PSDK battleEngineMethod "s_explosion"`.
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 23|unprefixed"`
  - echec attendu : `s_explosion` absent du manifest et extracteur a `Total registered methods: 0` sur fixture non prefixee.
- `dart test test/psdk_battle_cli_test.dart --name "Explosion scenario"`
  - echec attendu : `Unknown --scenario value "explosion"`.

Vert observe apres implementation :

- `dart test test/psdk_move_families/self_destruct_move_behavior_test.dart`
  - `00:00 +6: All tests passed!`
- `dart test test/psdk_registry_manifest_test.dart --name "Lot 23|unprefixed"`
  - `00:00 +2: All tests passed!`
- `dart test test/psdk_battle_cli_test.dart --name "Explosion scenario"`
  - `00:00 +1: All tests passed!`

## Commandes de validation

Format :

```bash
cd packages/map_battle
dart format --set-exit-if-changed lib/src/domain/move/behaviors/self_destruct_move_behavior.dart lib/src/data/static_basic_move_registry.dart lib/src/psdk/cli/psdk_battle_cli.dart tool/extract_psdk_move_registry.dart test/psdk_move_families/self_destruct_move_behavior_test.dart test/psdk_registry_manifest_test.dart test/psdk_battle_cli_test.dart lib/src/data/generated/psdk_move_registry_manifest.dart
```

Resultat exact :

```text
Formatted 8 files (0 changed) in 0.04 seconds.
```

Analyse :

```bash
cd packages/map_battle
dart analyze
```

Resultat exact :

```text
Analyzing map_battle...
No issues found!
```

Suite complete :

```bash
cd packages/map_battle
dart test
```

Resultat exact :

```text
00:02 +402: All tests passed!
```

Builds :

```bash
cd packages/map_battle
dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_lot23
dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_lot23
dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_lot23
```

Resultats exacts :

```text
Generated: /tmp/psdk_battle_cli_lot23
Generated: /tmp/extract_psdk_move_registry_lot23
Generated: /tmp/extract_psdk_effect_matrix_lot23
```

CLI smoke :

```bash
cd packages/map_battle
dart run bin/psdk_battle_cli.dart --scenario explosion --format json
```

Resultat exact :

```json
{"outcome":"defeat","turns":1,"playerHp":0,"opponentHp":92,"events":[{"kind":"turn_started","turn":1},{"kind":"move_pp_spent","user":{"bank":0,"position":0},"moveId":"explosion","spent":1,"remainingPp":34},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"explosion","moveName":"explosion"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"explosion"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"explosion","damage":8,"remainingHp":92},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":0,"position":0},"moveId":"explosion","damage":100,"remainingHp":0},{"kind":"battle_ended","outcome":"defeat"}]}
```

Diff hygiene :

```bash
git diff --check
```

Resultat exact :

```text
<aucune sortie, exit 0>
```

## Etat git final

Le worktree reste sale a cause des lots precedents et des zones non suivies. Les changements de ce lot se trouvent dans :

- `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/self_destruct_move_behavior_test.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`
- `reports/psdk-battle-map-battle-self-destruct-lot23-report.md`

## Verdicts des passes type sub-agent

### Audit / Architecture

Verdict Curie : lot petit centre sur `s_explosion`, statut `partial`, ne pas inclure `s_misty_explosion` tant que terrain Misty absent. `Damp` impossible sans ability snapshot.

Decision appliquee.

### Implementation

Verdict local : implementation minimale et isolee dans une nouvelle famille de move. Aucun changement dans le runner, le calculateur de degats ou les contrats publics.

### Tests

Verdict local : les tests couvrent hit, miss, immunite, Protect, PP vide, ordre secondaires/self-KO, extracteur, manifest et CLI.

### Build / Validation

Verdict local : format, analyse, suite complete `map_battle`, compilation CLI et extracteurs, smoke CLI `explosion` passent.

### Critique finale

Verdict local :

- Pas de port opportuniste de `MistyExplosion`.
- Pas de faux statut `ported`.
- Le correctif d'extraction est volontairement filtre sur `s_` pour eviter les registres non-move.
- Le comportement Protect est documente comme adaptation du reason Dart `protected` vers la semantique PSDK `:immunity`.
- Risque restant accepte : pas de `Damp`, pas de multi-cible, pas de terrain.

## Limites conservees

- `Damp` non supporte.
- `MistyExplosion` non supporte.
- Multi-target Explosion non supporte.
- Messages PSDK exacts non supportes.
- Faint callbacks complets non supportes.

## Prochaines etapes proposees

- Ajouter un snapshot d'abilities dans `PsdkBattleCombatantSetup` et un hook global de prevention pour `Damp`.
- Ajouter un etat terrain PSDK propre avant de porter `s_misty_explosion`, `s_expanding_force`, `s_rising_voltage`, `s_grassy_glide`.
- Introduire une cible multi-combatant propre avant de pretendre porter Explosion en doubles.

## Contenu complet des fichiers crees

### `packages/map_battle/lib/src/domain/move/behaviors/self_destruct_move_behavior.dart`

```dart
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

/// Partially ports PSDK `SelfDestruct`, registered as `s_explosion`.
///
/// PSDK keeps Self-Destruct and Explosion on the same Ruby class. Its local
/// effect removes the user's *current* HP after a successful Basic damage
/// pipeline, and also after target-immunity failures. The Dart procedure has a
/// distinct `protected` reason, so Protect is mapped to the same self-KO branch
/// because PSDK reaches it through the `:immunity` failure path.
///
/// `Damp` intentionally stays out of this lot: the current PSDK combatant
/// snapshot has no ability field, so claiming full parity would be dishonest.
final class SelfDestructMoveBehavior implements BattleMoveBehavior {
  const SelfDestructMoveBehavior.explosion()
      : battleEngineMethod = 's_explosion';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldSelfKoAfterFailure(prepared.failureReason)) {
        return _selfKoUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: <PsdkBattleEvent>[
            ...prepared.events,
            PsdkBattleAnimationCueEvent(
              user: context.user,
              target: context.target,
              moveId: context.move.id,
            ),
          ],
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return _selfKoUser(
        context: context,
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];

    // PSDK runs `deal_status` and `deal_stats` before `deal_effect` on
    // BasicWithSuccessfulEffect. Keeping riders before self-KO prevents a
    // future faint-process layer from masking successful secondary effects.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return _selfKoUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldSelfKoAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.immunity => true,
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  BattleMoveBehaviorResolution _selfKoUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    final selfDamage = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      amount: user.currentHp,
    );

    return BattleMoveBehaviorResolution(
      state: selfDamage.state,
      rng: rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (selfDamage.event != null) selfDamage.event!,
      ],
      successful: successful,
    );
  }
}
```

### `packages/map_battle/test/psdk_move_families/self_destruct_move_behavior_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK SelfDestruct move family', () {
    test('s_explosion damages the target before self-KOing the user', () {
      final result = _runMove(
        playerCurrentHp: 37,
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(2));
      expect(damage.first.target, psdkOpponentSlot);
      expect(damage.first.damage, 8);
      expect(damage.first.remainingHp, 92);
      expect(damage.last.target, psdkPlayerSlot);
      expect(damage.last.damage, 37);
      expect(damage.last.remainingHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion does not self-KO when accuracy misses', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          accuracy: 1,
          battleEngineMethod: 's_explosion',
        ),
        rngSeeds: const BattleRngSeeds(
          moveDamage: 1,
          moveCritical: 99999,
          moveAccuracy: 99,
          generic: 4,
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
          events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'move_declared',
            'miss',
          ]));
      expect(_damageEvents(result, moveId: 'explosion'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.outcome, isNull);
    });

    test('s_explosion self-KOs when the target is type-immune', () {
      final result = _runMove(
        playerCurrentHp: 13,
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
          events.map((event) => event.kind),
          containsAllInOrder(<String>[
            'move_immune',
            'animation_cue',
            'damage',
          ]));
      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkPlayerSlot);
      expect(damage.single.damage, 13);
      expect(damage.single.remainingHp, 0);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion self-KOs when blocked by Protect', () {
      final result = _runMove(
        opponentEffects: PsdkBattleEffectStack(
          values: const <String>[PsdkBattleEffectIds.protect],
        ),
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(events.map((event) => event.kind), <String>[
        'move_pp_spent',
        'move_declared',
        'move_failed',
        'animation_cue',
        'damage',
      ]);
      expect((events[2] as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.protected.jsonName);
      final damage = _damageEvents(result, moveId: 'explosion');
      expect(damage, hasLength(1));
      expect(damage.single.target, psdkPlayerSlot);
      expect(damage.single.damage, 100);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 0);
      expect(result.state.outcome?.kind, PsdkBattleOutcomeKind.defeat);
    });

    test('s_explosion does not self-KO when PP prevents execution', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          currentPp: 0,
          battleEngineMethod: 's_explosion',
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect((events.single as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.pp.jsonName);
      expect(_damageEvents(result, moveId: 'explosion'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(result.state.outcome, isNull);
    });

    test('s_explosion applies secondary effects before successful self-KO', () {
      final result = _runMove(
        playerMove: _move(
          id: 'explosion',
          power: 40,
          battleEngineMethod: 's_explosion',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final events = _eventsFor(result, moveId: 'explosion');
      expect(
        events.map((event) => event.kind),
        containsAllInOrder(<String>[
          'damage',
          'status',
          'damage',
        ]),
      );
      expect(result.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
      expect(_damageEvents(result, moveId: 'explosion').last.target,
          psdkPlayerSlot);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'fire'),
  PsdkBattleEffectStack? opponentEffects,
  BattleRngSeeds rngSeeds = const BattleRngSeeds(
    moveDamage: 1,
    moveCritical: 99999,
    moveAccuracy: 3,
    generic: 4,
  ),
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        maxHp: 100,
        currentHp: playerCurrentHp,
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        maxHp: 100,
        currentHp: 100,
        speed: 1,
        types: opponentTypes,
        effects: opponentEffects,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: rngSeeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int maxHp,
  required int currentHp,
  required int speed,
  required PsdkBattleTypes types,
  required PsdkBattleMoveData move,
  PsdkBattleEffectStack? effects,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: maxHp,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    effects: effects,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int pp = 35,
  int? currentPp,
  String battleEngineMethod = 's_basic',
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
    statuses: statuses,
  );
}

List<PsdkBattleEvent> _eventsFor(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .where((event) => event.toJson()['moveId'] == moveId)
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
```

## Zones modifiees principales

### Registre statique

```dart
import '../domain/move/behaviors/self_destruct_move_behavior.dart';

const SelfDestructMoveBehavior.explosion(),
```

### Extracteur

```dart
final _registerPattern = RegExp(
  r'(?:Move\.)?register\(:((?:s_)[a-zA-Z0-9_]+),\s*([A-Za-z0-9_:]+)\)',
);

's_explosion': _KnownDartBehavior(
  dartBehavior: 'SelfDestructMoveBehavior.explosion',
  status: _PsdkPortStatus.partial,
),
```

### CLI

```dart
'explosion' ||
'self_destruct' ||
'self-destruct' =>
  _PsdkBattleCliScenario.explosion,
```

### Manifest / matrice

```text
| `s_explosion` | `SelfDestruct` | `10 Move/2 Definitions/300 SelfDestruct.rb` | `SelfDestructMoveBehavior.explosion` | `partial` |
| `s_misty_explosion` | `MistyExplosion` | `10 Move/2 Definitions/300 TerrainDamageMoves.rb` | `TODO` | `missing` |
```
