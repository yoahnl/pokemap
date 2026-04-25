# Lot 22 - PSDK MindBlown self-crash moves

## Resume executif

Ce lot porte partiellement la classe Ruby Pokemon SDK
`Battle::Move::MindBlown` dans la voie clean architecture `packages/map_battle`.
Le scope couvre les trois
registrations PSDK trouvees dans `300 MindBlown.rb`:

- `s_mind_blown`
- `s_steel_beam`
- `s_chloroblast`

Le comportement Dart execute le pipeline commun PSDK deja porte
(declaration, accuracy, Protect, immunite, animation, dommages), puis applique
le crash utilisateur de `user.maxHp ~/ 2`. Sur un hit reussi, les riders
secondaires passent avant le crash, comme dans `Procedure.rb`
(`deal_damage && effect_working? && deal_status && deal_stats && deal_effect`).
Sur miss, immunite type ou blocage Protect, le crash est aussi applique et le
move reste non-successful.

Le lot reste volontairement `partial`: `Damp` et `Wonder Guard` sont dans Ruby
PSDK, mais le snapshot `PsdkBattleCombatant` ne transporte pas encore les
abilities.

## Confirmation du scope

Inclus:

- lecture de `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 MindBlown.rb`;
- comportement commun pour `s_mind_blown`, `s_steel_beam`, `s_chloroblast`;
- crash sur hit, miss, type-immunity et Protect;
- non-crash si PP vide, car le runner bloque avant la resolution de behavior;
- scenario CLI `mind_blown`;
- mise a jour extracteur, manifeste et matrice de porting;
- tests ciblant positif, negatif, garde-fous et non-regression Chloroblast.

Hors scope conserve:

- `SelfDestruct` / `Explosion`, classe PSDK separee et semantique differente;
- `Damp` user-prevention;
- exemption `Wonder Guard`;
- messages localises PSDK et visual ability hooks;
- multi-target exact et faint-process complet.

## Audit initial

Fichiers PSDK consultes:

- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 MindBlown.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 SelfDestruct.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 RecoilMove.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/100 Basic.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/130 Move Prevention.rb`

Constats:

- `MindBlown < Basic` surcharge `on_move_failure`, `deal_damage` et
  `deal_effect`.
- `on_move_failure` crash uniquement pour `:accuracy` et `:immunity`.
- Dans PSDK, Protect-style target prevention passe par
  `accuracy_immunity_test`, retire les targets, puis appelle
  `on_move_failure(..., :immunity)`. La voie Dart garde un reason separe
  `protected`, mais doit conserver le crash.
- `deal_effect` intervient apres les riders de statut/stats sur hit reussi.
- `SelfDestruct` utilise `BasicWithSuccessfulEffect` et se KO via un effet
  separe; il ne doit pas etre melange a ce lot.
- `chloroblast` apparait aussi dans la table PSDK `RecoilMove`, mais son
  `battleEngineMethod` manifeste pointe vers `MindBlown`; il ne doit donc pas
  etre traite comme `s_recoil`.

Fichiers Dart audites:

- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/recoil_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/direct_hp_move_behavior.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`

Risques identifies:

- perdre la raison d'echec dans `PreparedBattleMove` empechait de differencier
  miss/immunite/Protect des autres echecs;
- positionner le crash avant les effets secondaires aurait diverge du pipeline
  Ruby PSDK;
- reclamer `ported` aurait ete faux sans abilities `Damp` / `Wonder Guard`.

## Etat git initial

Le worktree etait deja sale avant ce lot. Points notables observes:

- modifications existantes hors scope dans `.idea`, `packages/map_core` et
  `packages/map_editor`;
- l'ensemble de la voie `packages/map_battle/lib/src/...`, `test/...` et
  `tool/...` etait deja largement non tracke par les lots precedents;
- les rapports et matrices PSDK etaient non trackes.

Aucune commande destructive n'a ete lancee et aucun fichier hors scope n'a ete
nettoye ou revert.

## Fichiers modifies, crees ou regeneres

### `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`

Zones modifiees:

- `prepareBattleMove`: conserve maintenant `BattleMoveProcedureResult.reason`;
- `PreparedBattleMove`: nouveau champ `failureReason`.

Pourquoi:

- `MindBlown` doit reagir differemment selon la raison d'echec.
- Les comportements existants continuent d'utiliser `toResolution()` sans
  changer leur contrat.

Impact attendu:

- aucun changement comportemental pour les familles existantes;
- nouvelle possibilite pour une famille de porter `on_move_failure`.

### `packages/map_battle/lib/src/domain/move/behaviors/mind_blown_move_behavior.dart`

Fichier cree.

Classes/fonctions:

- `MindBlownMoveBehavior.mindBlown`
- `MindBlownMoveBehavior.steelBeam`
- `MindBlownMoveBehavior.chloroblast`
- `_shouldCrashAfterFailure`
- `_crashUser`

Pourquoi:

- port direct de la classe PSDK `MindBlown`.
- trois constructors pour garder le registre explicite methode par methode.

Impact attendu:

- execution de `s_mind_blown`, `s_steel_beam`, `s_chloroblast`;
- events `damage` target puis self-damage sur hit;
- events `miss` / `move_immune` / `move_failed protected` puis self-damage sur
  echec concerne;
- `successful=false` sur crash d'echec.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Zones modifiees:

- import de `mind_blown_move_behavior.dart`;
- ajout des trois registrations:
  - `MindBlownMoveBehavior.mindBlown`
  - `MindBlownMoveBehavior.steelBeam`
  - `MindBlownMoveBehavior.chloroblast`

Pourquoi:

- rendre les trois `battleEngineMethod` executables via le registre par defaut.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Zones modifiees:

- ajout enum `_PsdkBattleCliScenario.mindBlown`;
- parsing `mind_blown` / `mind-blown`;
- message d'erreur `--scenario` mis a jour;
- fixture `_scenarioConfig` avec move `mind_blown`, type fire, special, power
  40, `battleEngineMethod: s_mind_blown`.

Pourquoi:

- permettre un smoke test CLI reproductible de la famille.

Impact attendu:

- `dart run bin/psdk_battle_cli.dart --scenario mind_blown --format json`
  produit `playerHp=50`, `opponentHp=88` et deux events damage pour
  `mind_blown`.

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones modifiees:

- `_knownDartBehaviors` ajoute:
  - `s_chloroblast -> MindBlownMoveBehavior.chloroblast -> partial`
  - `s_mind_blown -> MindBlownMoveBehavior.mindBlown -> partial`
  - `s_steel_beam -> MindBlownMoveBehavior.steelBeam -> partial`

Pourquoi:

- synchroniser l'extraction avec le runtime reel et eviter un manifeste qui
  annonce `TODO`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Fichier regenere par:

```bash
dart run tool/extract_psdk_move_registry.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-move-porting-matrix.md --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
```

Impact:

- `s_chloroblast`, `s_mind_blown`, `s_steel_beam` passent de `missing` a
  `partial`.

### `reports/psdk-move-porting-matrix.md`

Fichier regenere par la meme commande.

Compteurs apres lot:

- total: 316
- `ported`: 19
- `partial`: 22
- `missing`: 275

Lignes clefs:

```text
| `s_chloroblast` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.chloroblast` | `partial` |
| `s_mind_blown` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.mindBlown` | `partial` |
| `s_steel_beam` | `MindBlown` | `10 Move/2 Definitions/300 MindBlown.rb` | `MindBlownMoveBehavior.steelBeam` | `partial` |
```

### `reports/psdk-effect-porting-matrix.md`

Commande relancee pour garder les matrices PSDK synchrones:

```bash
dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-effect-porting-matrix.md
```

Aucun changement fonctionnel attendu dans ce lot cote effects.

### `packages/map_battle/test/psdk_move_families/mind_blown_move_behavior_test.dart`

Fichier cree.

Couverture:

- hit positif pour les trois registrations;
- `chloroblast` verifie explicitement qu'il utilise la moitie des PV max et non
  le recoil base sur dommages infliges;
- miss accuracy pour les trois registrations;
- immunite type pour les trois registrations;
- Protect pour les trois registrations;
- PP vide sans crash;
- riders secondaires avant crash sur hit reussi.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Zone modifiee:

- nouveau test `tracks the Lot 22 MindBlown self-crash slice`.

Pourquoi:

- empecher une regression manifeste/matrice ou une methode repasserait `TODO`.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Zone modifiee:

- nouveau test CLI `prints a Mind Blown scenario with target damage and self crash`.

Pourquoi:

- garantir que le CLI expose vraiment la nouvelle famille.

## Tests rouges observes avant implementation

Commandes:

```bash
cd packages/map_battle && dart test test/psdk_move_families/mind_blown_move_behavior_test.dart
cd packages/map_battle && dart test test/psdk_registry_manifest_test.dart --name "Lot 22"
cd packages/map_battle && dart test test/psdk_battle_cli_test.dart --name "Mind Blown scenario"
```

Resultats rouges:

- famille MindBlown: 9 echecs, cause attendue
  `Unsupported PSDK battleEngineMethod "s_mind_blown"` / `s_steel_beam` /
  `s_chloroblast`;
- manifeste: `Expected PsdkPortStatus.partial`, `Actual PsdkPortStatus.missing`;
- CLI: `Unknown --scenario value "mind_blown"`.

## Tests et validations lancees apres implementation

Format:

```bash
cd packages/map_battle && dart format --set-exit-if-changed lib/src/domain/move/behaviors/battle_move_behavior_support.dart lib/src/domain/move/behaviors/mind_blown_move_behavior.dart lib/src/data/static_basic_move_registry.dart lib/src/psdk/cli/psdk_battle_cli.dart test/psdk_move_families/mind_blown_move_behavior_test.dart test/psdk_battle_cli_test.dart test/psdk_registry_manifest_test.dart tool/extract_psdk_move_registry.dart lib/src/data/generated/psdk_move_registry_manifest.dart
```

Resultat final: `Formatted 9 files (0 changed) in 0.03 seconds.`

Tests ciblés:

```bash
cd packages/map_battle && dart test test/psdk_move_families/mind_blown_move_behavior_test.dart
```

Resultat: `+15: All tests passed!`

```bash
cd packages/map_battle && dart test test/psdk_registry_manifest_test.dart --name "Lot 22"
```

Resultat: `+1: All tests passed!`

```bash
cd packages/map_battle && dart test test/psdk_battle_cli_test.dart --name "Mind Blown scenario"
```

Resultat: `+1: All tests passed!`

Analyse:

```bash
cd packages/map_battle && dart analyze
```

Resultat: `No issues found!`

Suite complete:

```bash
cd packages/map_battle && dart test
```

Resultat: `+393: All tests passed!`

Build / compilation:

```bash
cd packages/map_battle && dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_lot22
cd packages/map_battle && dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_lot22
cd packages/map_battle && dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_lot22
```

Resultats:

- `Generated: /tmp/psdk_battle_cli_lot22`
- `Generated: /tmp/extract_psdk_move_registry_lot22`
- `Generated: /tmp/extract_psdk_effect_matrix_lot22`

CLI smoke direct:

```bash
cd packages/map_battle && dart run bin/psdk_battle_cli.dart --scenario mind_blown --format json
```

Resultat clef:

- `outcome=ongoing`
- `turns=1`
- `playerHp=50`
- `opponentHp=88`
- events `mind_blown`: target damage `12`, self damage `50`.

Whitespace:

```bash
git diff --check
```

Resultat: exit 0, aucune sortie.

## Etat git final

Le worktree reste sale comme avant le lot, avec les changements `map_battle`
non trackes des lots precedents. Nouveaux elements du lot dans ce contexte:

- `packages/map_battle/lib/src/domain/move/behaviors/mind_blown_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/mind_blown_move_behavior_test.dart`
- `reports/psdk-battle-map-battle-mind-blown-lot22-report.md`

Et modifications dans les fichiers de registre, CLI, tests et matrices listes
plus haut.

## Verdicts des sub-agents / passes

- Sub-agent Audit / Architecture (`Kuhn`): OK pour un lot MindBlown autonome.
  `SelfDestruct` doit rester separe. Note: `s_steel_beam` est sur la meme
  classe PSDK; je l'ai inclus pour eviter une demi-portee artificielle.
- Sub-agent Implementation (passe locale): OK. Implementation minimale, un
  nouveau behavior, aucune ability ajoutee.
- Sub-agent Tests (passe locale): OK. Rouge observe avant implementation,
  puis tests ciblés et suite complete verts.
- Sub-agent Build / Validation (passe locale): OK. Analyse, compilation CLI et
  outils, CLI smoke direct, `git diff --check` valides.
- Sub-agent Critique finale (`Lorentz`): OK sans bloquant. Deux remarques P3
  ont ete adressees: parametrer les echecs miss/immunite/Protect sur les trois
  methods, et expliciter le commentaire de port partiel.
- Sub-agent Critique finale bis (`Dirac`): OK final en lecture seule. Aucun
  finding bloquant, P2 ou P3 nouveau; les deux P3 precedents sont confirmes
  corriges.

## Limites explicitement conservees

- `Damp` ne bloque pas encore ces moves.
- `Wonder Guard` n'annule pas encore le crash.
- Les messages PSDK et animations d'ability ne sont pas modelises.
- Les faint-process callbacks complets restent hors scope.
- Le statut manifeste reste donc `partial`, pas `ported`.

## Auto-critique finale

- Le choix d'inclure `s_steel_beam` elargit legerement le nom initial
  pressenti (`Mind Blown / Chloroblast`), mais il suit la source PSDK exacte:
  les trois methods sont enregistrees sur la meme classe Ruby.
- La critique finale a releve que les echecs n'etaient d'abord testes que sur
  `s_mind_blown`; les tests couvrent maintenant miss, immunite et Protect pour
  `s_mind_blown`, `s_steel_beam` et `s_chloroblast`.
- `PreparedBattleMove.failureReason` est une petite extension du contrat
  interne; elle est necessaire pour porter les overrides `on_move_failure`
  sans dupliquer tout le pipeline.
- Le support d'abilities serait tentant mais aurait cree un chantier transversal
  dans `PsdkBattleCombatant`; il est volontairement reporte.

## Prochaines etapes proposees

- Porter `SelfDestruct` / `Explosion` comme lot distinct.
- Ajouter un vrai contrat ability dans le snapshot PSDK avant de cloturer
  `Damp`, `Wonder Guard`, `Rock Head`, `Reckless`, etc.
- Ensuite seulement reevaluer si `MindBlownMoveBehavior` peut passer de
  `partial` a `ported`.

## Contenu complet des fichiers crees

### `packages/map_battle/lib/src/domain/move/behaviors/mind_blown_move_behavior.dart`

```dart
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

/// Partially ports the PSDK `MindBlown` Ruby class.
///
/// Pokemon SDK registers Mind Blown, Steel Beam and Chloroblast on the same
/// class. They are not regular recoil moves: after a successful Basic hit they
/// run `deal_effect`, which removes half of the user's max HP. The same crash
/// also happens when accuracy or target immunity prevents the hit. Ability
/// gates (`Damp`, `Wonder Guard`) remain outside this slice because the PSDK
/// combatant snapshot does not carry ability data yet.
final class MindBlownMoveBehavior implements BattleMoveBehavior {
  const MindBlownMoveBehavior.mindBlown() : battleEngineMethod = 's_mind_blown';

  const MindBlownMoveBehavior.steelBeam() : battleEngineMethod = 's_steel_beam';

  const MindBlownMoveBehavior.chloroblast()
      : battleEngineMethod = 's_chloroblast';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldCrashAfterFailure(prepared.failureReason)) {
        return _crashUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: prepared.events,
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
      return _crashUser(
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

    // PSDK `MindBlown < Basic` reaches `deal_effect` after secondary status
    // and stat riders (`deal_status` / `deal_stats`). Keeping this order here
    // prevents the self-crash from hiding riders when the user faints.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return _crashUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldCrashAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.accuracy ||
      BattleMoveFailureReason.immunity =>
        true,
      // In Ruby PSDK, Protect-style target prevention removes all actual
      // targets inside `accuracy_immunity_test`, then calls `on_move_failure`
      // with `:immunity`. The Dart lane keeps a clearer `protected` reason for
      // event consumers, but the MindBlown crash semantics are the same.
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  BattleMoveBehaviorResolution _crashUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    final crash = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      amount: user.maxHp ~/ 2,
    );

    return BattleMoveBehaviorResolution(
      state: crash.state,
      rng: rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (crash.event != null) crash.event!,
      ],
      successful: successful,
    );
  }
}
```

### `packages/map_battle/test/psdk_move_families/mind_blown_move_behavior_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _mindBlownMethods = <String, String>{
  's_mind_blown': 'mind_blown',
  's_steel_beam': 'steel_beam',
  's_chloroblast': 'chloroblast',
};

void main() {
  group('PSDK MindBlown move families', () {
    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} applies target damage and half max HP crash', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(2));
        expect(damage.first.target, psdkOpponentSlot);
        expect(damage.first.damage, 8);
        expect(damage.first.remainingHp, 92);
        expect(damage.last.target, psdkPlayerSlot);
        expect(damage.last.damage, 50);
        expect(damage.last.remainingHp, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 92);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    test('s_chloroblast uses half max HP instead of recoil from damage dealt',
        () {
      final result = _runMove(
        playerCurrentHp: 80,
        playerMove: _move(
          id: 'chloroblast',
          power: 40,
          battleEngineMethod: 's_chloroblast',
        ),
      );

      final damage = _damageEvents(result, moveId: 'chloroblast');
      expect(damage, hasLength(2));
      expect(damage.first.damage, 8);
      expect(damage.last.damage, 50);
      expect(damage.last.remainingHp, 30);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 30);
    });

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when the move misses', () {
        final result = _runMove(
          playerMove: _move(
            id: entry.value,
            power: 40,
            accuracy: 1,
            battleEngineMethod: entry.key,
          ),
          rngSeeds: const BattleRngSeeds(
            moveDamage: 1,
            moveCritical: 99999,
            moveAccuracy: 99,
            generic: 4,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(
            events.map((event) => event.kind),
            containsAllInOrder(<String>[
              'miss',
              'damage',
            ]));
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(1));
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when the target is type-immune', () {
        final result = _runMove(
          opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(
            events.map((event) => event.kind),
            containsAllInOrder(<String>[
              'move_immune',
              'damage',
            ]));
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage, hasLength(1));
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    for (final entry in _mindBlownMethods.entries) {
      test('${entry.key} crashes the user when blocked by Protect', () {
        final result = _runMove(
          opponentEffects: PsdkBattleEffectStack(
            values: const <String>[PsdkBattleEffectIds.protect],
          ),
          playerMove: _move(
            id: entry.value,
            power: 40,
            battleEngineMethod: entry.key,
          ),
        );

        final events = _eventsFor(result, moveId: entry.value);
        expect(events.map((event) => event.kind), <String>[
          'move_pp_spent',
          'move_declared',
          'move_failed',
          'damage',
        ]);
        expect((events[2] as PsdkBattleMoveFailedEvent).reason,
            BattleMoveFailureReason.protected.jsonName);
        final damage = _damageEvents(result, moveId: entry.value);
        expect(damage.single.target, psdkPlayerSlot);
        expect(damage.single.damage, 50);
        expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
        expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 50);
      });
    }

    test('s_mind_blown does not crash when PP prevents move execution', () {
      final result = _runMove(
        playerMove: _move(
          id: 'mind_blown',
          power: 40,
          currentPp: 0,
          battleEngineMethod: 's_mind_blown',
        ),
      );

      final events = _eventsFor(result, moveId: 'mind_blown');
      expect(events.map((event) => event.kind), <String>['move_failed']);
      expect((events.single as PsdkBattleMoveFailedEvent).reason,
          BattleMoveFailureReason.pp.jsonName);
      expect(_damageEvents(result, moveId: 'mind_blown'), isEmpty);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 100);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('s_mind_blown applies secondary effects before successful crash', () {
      final result = _runMove(
        playerMove: _move(
          id: 'mind_blown',
          power: 40,
          battleEngineMethod: 's_mind_blown',
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.burn,
              chance: 100,
            ),
          ],
        ),
      );

      final events = _eventsFor(result, moveId: 'mind_blown');
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
      expect(_damageEvents(result, moveId: 'mind_blown').last.target,
          psdkPlayerSlot);
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerMaxHp = 100,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
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
        maxHp: playerMaxHp,
        currentHp: playerCurrentHp,
        speed: 100,
        types: const PsdkBattleTypes(primary: 'fire'),
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        maxHp: 100,
        currentHp: opponentCurrentHp,
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
