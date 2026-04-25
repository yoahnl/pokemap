# PSDK Battle Map Battle Variable Power Lot 16 Report

## Nom exact du lot

Lot 16 - tranche variable power / status damage PSDK dans `packages/map_battle`.

## Resume executif

Cette tranche ajoute un port Dart clean architecture de 12 methodes Pokemon SDK dont le comportement principal depend d'une puissance dynamique ou d'un statut majeur deja present:

- `s_brine`
- `s_eruption`
- `s_flail`
- `s_wring_out`
- `s_hard_press`
- `s_electro_ball`
- `s_gyro_ball`
- `s_facade`
- `s_infernal_parade`
- `s_bitter_malice`
- `s_hex`
- `s_venoshock`

Le port reste dans `map_battle`, en pur Dart, sans dependance Flutter/Flame. La definition catalogue des moves reste immuable; les puissances dynamiques passent par `BattleMoveDamageOverrides`, un objet local a un calcul de degats.

## Confirmation du scope

Inclus:

- Formules PSDK base power: Brine, Eruption, Flail, Wring Out, Hard Press, Electro Ball, Gyro Ball, Facade, Infernal Parade, Bitter Malice.
- Formules PSDK final damage: Hex, Venoshock.
- Injection de `majorStatus` depuis `PsdkBattleCombatantSetup`.
- Option explicite `clearMajorStatus` dans `PsdkBattleCombatant.copyWith`.
- Scenario CLI `variable_power`.
- Mise a jour du manifest et de la matrice PSDK.

Exclus volontairement:

- `Body Press`, `Foul Play`, `Psyshock`: ils demandent des overrides de source de stat et les stages ne sont pas encore portes completement.
- `Low Kick`, `Heavy Slam`: poids absent du state.
- `Acrobatics`, `Fling`, `Natural Gift`, `Knock Off`, `Belch`: items/berries absents.
- `Payback`, `Revenge`, `Assurance`, `Avalanche`: historique de degats intra-tour absent.
- Branche `Hex + Comatose`: abilities absentes, donc `s_hex` reste `partial`.
- Parite exacte Ruby bug-for-bug de `Gyro Ball`: Dart applique le clamp voulu par le code Ruby; la matrice garde `s_gyro_ball` en `partial`.

## Audit initial

Fichiers et contrats audites:

- `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`: formule de degats centralisee, stats choisies par categorie, pas d'override initial.
- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`: pipeline commun PSDK pour target, accuracy, Protect et immunite.
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`: registre statique des behaviors deja portes.
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`: state combatant avec `majorStatus` cote runtime mais pas cote setup.
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`: scenarios CLI existants.
- `packages/map_battle/tool/extract_psdk_move_registry.dart`: source de verite pour le manifest/matrice.
- Scripts PSDK sous `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions`.

Risques identifies:

- Ne pas reconstruire `BattleMoveDefinition` pour une puissance temporaire.
- Ne pas marquer `ported` des methodes qui dependent d'abilities ou de bugs Ruby ambigus.
- Eviter de mentir sur `Hex` et `Gyro Ball`.
- Ajouter des tests de frontieres pour les seuils stricts PSDK.

## Etat git initial

Le worktree etait deja sale avant ce lot:

- Modifications existantes dans `.idea`, `packages/map_core`, `packages/map_editor`.
- Nombreux fichiers `packages/map_battle` et `reports/psdk-*` deja non suivis par Git, correspondant aux lots precedents.

Je n'ai pas revert ces changements.

## Fichiers modifies ou crees

### `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`

Zones modifiees:

- `BattleMoveDamageContext`: ajout de `BattleMoveDamageOverrides? overrides`.
- Nouveau `BattleMoveDamageOverrides`.
- `BattleMoveDamageCalculator.calculate`: utilise `overrides.power`, `overrides.offensiveStat`, `overrides.defensiveStat`.

Raison:

- Permettre aux classes PSDK de modifier une entree de formule au moment du hit, sans modifier la definition catalogue du move.

Impact attendu:

- Les moves dynamiques peuvent appeler la formule centrale avec leur puissance reelle.
- Les prochains moves custom stat source pourront reutiliser le meme contrat.

### `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`

Statut: fichier cree.

Raison:

- Regrouper les familles PSDK dont l'override principal est `real_base_power` ou un doublement final de degats.

Impact attendu:

- Port executable des 12 methodes listees dans le scope.
- Pipeline commun conserve: PP, declaration, animation, accuracy, Protect, immunite, damage, secondary effects.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Zones modifiees:

- Import de `variable_power_move_behavior.dart`.
- Enregistrement des 12 constructors `VariablePowerMoveBehavior`.

Raison:

- Rendre les `battleEngineMethod` PSDK supportes par le moteur.

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`

Zones modifiees:

- `PsdkBattleCombatantSetup`: ajout de `majorStatus`.
- `PsdkBattleCombatant.fromSetup`: transmission de `majorStatus`.
- `PsdkBattleCombatant.copyWith`: ajout de `clearMajorStatus`.

Raison:

- Plusieurs formules PSDK lisent le statut avant l'action.
- Les futurs effets de soin/cure doivent pouvoir retirer un statut sans hack nullable.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Zones modifiees:

- Nouveau scenario `_PsdkBattleCliScenario.variablePower`.
- Parsing `variable_power` / `variable-power`.
- Fixture CLI Brine a 50 PV cible.

Raison:

- Donner aux sub-agents et au thread principal un scenario CLI pour smoke tester la tranche.

### `packages/map_battle/test/psdk_move_families/variable_power_test.dart`

Statut: fichier cree.

Raison:

- Tests TDD pour les familles variables: positif, negatif, seuils stricts, statut user/target, doublement final.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Zones modifiees:

- Ajout du test `variable_power`.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Zones modifiees:

- Ajout d'un test de statut manifest pour la tranche variable-power.

### `packages/map_battle/test/psdk_battler_state_test.dart`

Zones modifiees:

- Ajout d'un groupe `PSDK clean combatant state` pour `clearMajorStatus`.

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones modifiees:

- Ajout des `_KnownDartBehavior` pour les 12 methodes.
- `s_hex` et `s_gyro_ball` marques `partial`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Regeneration par outil.

### `reports/psdk-move-porting-matrix.md`

Regeneration par outil.

Etat apres regeneration:

- Total registered methods: 316
- `ported`: 16
- `partial`: 6
- `missing`: 294

### `reports/psdk-effect-porting-matrix.md`

Regeneration par outil, sans changement fonctionnel attendu pour ce lot.

## Tests crees ou modifies

Tests crees:

- `packages/map_battle/test/psdk_move_families/variable_power_test.dart`

Tests modifies:

- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/test/psdk_battler_state_test.dart`

Couvertures principales:

- Brine double seulement a la demi-vie cible.
- Eruption scale sur HP user avec puissance minimum.
- Flail table stricte PSDK avec frontieres exactes.
- Wring Out / Hard Press scale sur HP cible.
- Electro Ball buckets stricts PSDK, incluant 24, 25, 32, 33, 49, 50, 99, 100.
- Gyro Ball ratio speed.
- Facade lit le statut du user.
- Infernal Parade / Bitter Malice lisent le statut de la cible.
- Hex double tout statut majeur connu.
- Venoshock double seulement poison/toxic.
- CLI `variable_power`.
- Manifest/matrice honnetes.
- `clearMajorStatus` pour les futurs effets cure.

## TDD RED observe

- `variable_power_test.dart` a d'abord echoue au chargement: `No named parameter with the name 'majorStatus'`.
- Apres ajout setup status, les tests ont echoue sur `Unsupported PSDK battleEngineMethod "s_brine"` et familles associees.
- `psdk_battle_cli_test.dart` a echoue sur `Unknown --scenario value "variable_power"`.
- `psdk_battler_state_test.dart` a echoue au chargement sur `No named parameter with the name 'clearMajorStatus'`.

## Commandes de test lancees

Commandes ciblees finales:

```bash
cd packages/map_battle && dart test test/psdk_move_families/variable_power_test.dart
```

Resultat: `+9: All tests passed!`

```bash
cd packages/map_battle && dart test test/psdk_battler_state_test.dart
```

Resultat: `+6: All tests passed!`

```bash
cd packages/map_battle && dart test test/psdk_battle_cli_test.dart
```

Resultat: `+12: All tests passed!`

```bash
cd packages/map_battle && dart test test/psdk_registry_manifest_test.dart
```

Resultat: `+10: All tests passed!`

Suite complete:

```bash
cd packages/map_battle && dart test
```

Resultat: `+329: All tests passed!`

## Commandes d'analyse lancees

```bash
cd packages/map_battle && dart analyze
```

Resultat exact: `Analyzing map_battle... No issues found!`

## Commandes de build lancees

```bash
cd packages/map_battle && dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_check
```

Resultat exact: `Generated: /tmp/psdk_battle_cli_check`

```bash
cd packages/map_battle && dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_check
```

Resultat exact: `Generated: /tmp/extract_psdk_move_registry_check`

```bash
cd packages/map_battle && dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_check
```

Resultat exact: `Generated: /tmp/extract_psdk_effect_matrix_check`

CLI smoke:

```bash
cd packages/map_battle && dart run bin/psdk_battle_cli.dart --scenario variable_power --format json
```

Resultat utile:

- `outcome`: `ongoing`
- `turns`: `1`
- `opponentHp`: `26`
- event `damage` pour `brine`: `damage=24`, `remainingHp=26`

Whitespace:

```bash
git diff --check
```

Resultat: sortie vide, exit 0.

## Sub-agents et passes nommees

### Sub-agent Audit / Architecture - Bacon

Verdict: recommander `BattleMoveDamageOverrides` plutot qu'un `copyWith` de definition catalogue.

Action prise: appliquee.

### Sub-agent Audit PSDK - Franklin

Verdict: shortlist safe sans nouveau contrat lourd: HP, speed, major status; exclure poids, items, abilities, damage history; stat source possible seulement avec extension calculateur.

Action prise: port des familles HP/speed/status; stat source repousse.

### Passe Implementation

Verdict: implementation locale a `map_battle`, pure Dart, sans toucher runtime/editor.

### Passe Tests

Verdict: tests RED/GREEN crees pour chaque famille et pour le CLI.

### Passe Build / Validation

Verdict: analyse, tests, compilations et CLI smoke passes.

### Sub-agent Critique finale - Parfit

Verdict initial: pas de critical, mais points a traiter:

- Electro Ball boundaries.
- `majorStatus` non effacable via `copyWith`.
- Tests trop relatifs.

Action prise:

- Verification du Ruby PSDK `300 ElectroBall.rb`: le code utilise `first > ratio`; le seuil exact 0.25 tombe donc dans le bucket 120, pas 150. La recommandation de passer en `<=` a ete rejetee pour rester PSDK.
- Ajout de tests exacts sur les frontieres Electro Ball.
- Ajout de tests exacts sur les frontieres Flail.
- Ajout de `clearMajorStatus`.

## Etat git final

Le worktree reste sale, comme au depart. Les changements de ce lot sont limites a `packages/map_battle` et aux rapports/matrices PSDK. Les modifications preexistantes dans `packages/map_core`, `packages/map_editor` et `.idea` n'ont pas ete revert.

## Limites conservees

- `s_hex` partial: pas de `Comatose`.
- `s_gyro_ball` partial: Dart applique le clamp voulu; PSDK Ruby calcule `power.clamp(1, 150)` sans reassigner explicitement.
- Pas de stat stages dans le calculateur de degats general.
- Pas de poids, item, ability, weather, terrain, hazards, party history ou damage history.
- Le scenario CLI `variable_power` ne couvre que Brine; les autres familles sont couvertes par les tests unitaires.

## Auto-critique finale

Points solides:

- Les familles portees reutilisent le pipeline commun.
- Les matrices distinguent ported/partial/missing.
- Les tests de frontieres protegent les seuils PSDK stricts.

Risques restants:

- Les stats stages n'etant pas encore appliquees dans le calculateur, les prochains moves stat source doivent etre portes avec un lot separe.
- Le statut majeur PSDK reste simple et ne porte pas les compteurs/effets complets.
- Gyro Ball doit etre tranche au niveau doc canonique: bug Ruby exact ou adaptation intentionnelle.

## Prochaines etapes proposees

- Lot 16 suivant: `Body Press`, `Foul Play`, `Psyshock` via `BattleMoveDamageOverrides.offensiveStat/defensiveStat` et tests de stat source.
- Lot suivant dedie: poids (`Low Kick`, `Heavy Slam`) avec ajout minimal au combatant setup.
- Lot suivant dedie: historique de degats intra-tour (`Payback`, `Revenge`, `Assurance`, `Avalanche`).

## Contenu complet des fichiers crees

### `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart`

```dart
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _VariablePowerKind {
  brine,
  eruption,
  flail,
  wringOut,
  hardPress,
  electroBall,
  gyroBall,
  facade,
  targetStatusPowerBoost,
  hex,
  venoshock,
}

/// Ports PSDK move classes whose main override is dynamic base power.
///
/// The class mirrors Ruby `real_base_power`/`damages` overrides while leaving
/// target selection, PP, accuracy, Protect, immunity and secondary riders in
/// the shared move procedure. Families needing items, abilities, weights,
/// weather, terrain, damage history or custom stat sources stay out of this
/// lot so the registry does not overstate support.
final class VariablePowerMoveBehavior implements BattleMoveBehavior {
  const VariablePowerMoveBehavior.brine()
      : battleEngineMethod = 's_brine',
        _kind = _VariablePowerKind.brine;

  const VariablePowerMoveBehavior.eruption()
      : battleEngineMethod = 's_eruption',
        _kind = _VariablePowerKind.eruption;

  const VariablePowerMoveBehavior.flail()
      : battleEngineMethod = 's_flail',
        _kind = _VariablePowerKind.flail;

  const VariablePowerMoveBehavior.wringOut()
      : battleEngineMethod = 's_wring_out',
        _kind = _VariablePowerKind.wringOut;

  const VariablePowerMoveBehavior.hardPress()
      : battleEngineMethod = 's_hard_press',
        _kind = _VariablePowerKind.hardPress;

  const VariablePowerMoveBehavior.electroBall()
      : battleEngineMethod = 's_electro_ball',
        _kind = _VariablePowerKind.electroBall;

  const VariablePowerMoveBehavior.gyroBall()
      : battleEngineMethod = 's_gyro_ball',
        _kind = _VariablePowerKind.gyroBall;

  const VariablePowerMoveBehavior.facade()
      : battleEngineMethod = 's_facade',
        _kind = _VariablePowerKind.facade;

  const VariablePowerMoveBehavior.infernalParade()
      : battleEngineMethod = 's_infernal_parade',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.bitterMalice()
      : battleEngineMethod = 's_bitter_malice',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.hex()
      : battleEngineMethod = 's_hex',
        _kind = _VariablePowerKind.hex;

  const VariablePowerMoveBehavior.venoshock()
      : battleEngineMethod = 's_venoshock',
        _kind = _VariablePowerKind.venoshock;

  @override
  final String battleEngineMethod;
  final _VariablePowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      user: user,
      target: target,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    final finalDamage = _resolveFinalDamage(
      damage: damageResult.damage,
      target: target,
    );
    if (finalDamage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: finalDamage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _resolvePower({
    required int movePower,
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.brine => _brinePower(movePower, target),
      _VariablePowerKind.eruption => _hpRatePower(movePower, user),
      _VariablePowerKind.flail => _flailPower(user),
      _VariablePowerKind.wringOut => _hpRatePower(120, target),
      _VariablePowerKind.hardPress => _hpRatePower(100, target),
      _VariablePowerKind.electroBall => _electroBallPower(user, target),
      _VariablePowerKind.gyroBall => _gyroBallPower(user, target),
      _VariablePowerKind.facade => _facadePower(movePower, user),
      _VariablePowerKind.targetStatusPowerBoost =>
        target.majorStatus == null ? movePower : movePower * 2,
      // Hex and Venoshock double final damage in PSDK, not base power.
      _VariablePowerKind.hex || _VariablePowerKind.venoshock => movePower,
    };
  }

  int _resolveFinalDamage({
    required int damage,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.hex =>
        target.majorStatus == null ? damage : damage * 2,
      _VariablePowerKind.venoshock =>
        _isPoisonStatus(target.majorStatus) ? damage * 2 : damage,
      _ => damage,
    };
  }

  int _brinePower(int movePower, PsdkBattleCombatant target) {
    return target.currentHp <= target.maxHp ~/ 2 ? movePower * 2 : movePower;
  }

  int _hpRatePower(int maxPower, PsdkBattleCombatant battler) {
    final power = (maxPower * _hpRate(battler)).floor();
    return power < 1 ? 1 : power;
  }

  int _flailPower(PsdkBattleCombatant user) {
    final rate = _hpRate(user);
    if (rate > 0.70) {
      return 20;
    }
    if (rate > 0.35) {
      return 40;
    }
    if (rate > 0.20) {
      return 80;
    }
    if (rate > 0.10) {
      return 100;
    }
    if (rate > 0.04) {
      return 150;
    }
    return 200;
  }

  int _electroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final ratio = _positiveSpeed(target) / _positiveSpeed(user);
    if (ratio < 0.25) {
      return 150;
    }
    if (ratio < 0.33) {
      return 120;
    }
    if (ratio < 0.5) {
      return 80;
    }
    if (ratio < 1) {
      return 60;
    }
    return 40;
  }

  int _gyroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final rawPower =
        (25 * _positiveSpeed(target) / _positiveSpeed(user)).floor();
    return rawPower.clamp(1, 150).toInt();
  }

  int _facadePower(int movePower, PsdkBattleCombatant user) {
    return _isFacadeBoostingStatus(user.majorStatus)
        ? movePower * 2
        : movePower;
  }

  double _hpRate(PsdkBattleCombatant battler) {
    if (battler.maxHp <= 0) {
      return 0;
    }
    return battler.currentHp.clamp(0, battler.maxHp) / battler.maxHp;
  }

  int _positiveSpeed(PsdkBattleCombatant battler) {
    final speed = battler.stats.speed;
    return speed < 1 ? 1 : speed;
  }

  bool _isFacadeBoostingStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.burn ||
      PsdkBattleMajorStatus.paralysis ||
      PsdkBattleMajorStatus.poison ||
      PsdkBattleMajorStatus.toxic =>
        true,
      _ => false,
    };
  }

  bool _isPoisonStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.poison || PsdkBattleMajorStatus.toxic => true,
      _ => false,
    };
  }
}
```

### `packages/map_battle/test/psdk_move_families/variable_power_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK variable-power move families', () {
    test('s_brine doubles base power only when the target is at half HP', () {
      final aboveHalf = _runMove(
        playerMove: _move(
          id: 'brine',
          battleEngineMethod: 's_brine',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 51,
      );
      final atHalf = _runMove(
        playerMove: _move(
          id: 'brine',
          battleEngineMethod: 's_brine',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 50,
      );

      expect(
        _damage(atHalf, moveId: 'brine'),
        greaterThan(_damage(aboveHalf, moveId: 'brine')),
      );
      expect(
        atHalf.state.battlerAt(psdkOpponentSlot).currentHp,
        50 - _damage(atHalf, moveId: 'brine'),
      );
    });

    test('s_eruption scales from the user HP rate with a one-power floor', () {
      final fullHp = _runMove(
        playerMove: _move(
          id: 'eruption',
          battleEngineMethod: 's_eruption',
          power: 150,
          category: PsdkBattleMoveCategory.special,
        ),
        playerCurrentHp: 100,
      );
      final lowHp = _runMove(
        playerMove: _move(
          id: 'eruption',
          battleEngineMethod: 's_eruption',
          power: 150,
          category: PsdkBattleMoveCategory.special,
        ),
        playerCurrentHp: 1,
      );

      expect(
        _damage(fullHp, moveId: 'eruption'),
        greaterThan(_damage(lowHp, moveId: 'eruption')),
      );
      expect(_damage(lowHp, moveId: 'eruption'), greaterThan(0));
    });

    test('s_flail uses the PSDK HP threshold table', () {
      final highHp = _runMove(
        playerMove: _move(
          id: 'flail',
          battleEngineMethod: 's_flail',
          power: 1,
        ),
        playerCurrentHp: 100,
      );
      final criticalHp = _runMove(
        playerMove: _move(
          id: 'flail',
          battleEngineMethod: 's_flail',
          power: 1,
        ),
        playerCurrentHp: 3,
      );

      expect(
        _damage(criticalHp, moveId: 'flail'),
        greaterThan(_damage(highHp, moveId: 'flail') * 5),
      );
    });

    test('s_wring_out and s_hard_press scale from target remaining HP', () {
      final wringOutFullTarget = _runMove(
        playerMove: _move(
          id: 'wring_out',
          battleEngineMethod: 's_wring_out',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 100,
      );
      final wringOutLowTarget = _runMove(
        playerMove: _move(
          id: 'wring_out',
          battleEngineMethod: 's_wring_out',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentCurrentHp: 25,
      );
      final hardPressFullTarget = _runMove(
        playerMove: _move(
          id: 'hard_press',
          type: 'steel',
          battleEngineMethod: 's_hard_press',
          power: 1,
        ),
        opponentCurrentHp: 100,
      );
      final hardPressLowTarget = _runMove(
        playerMove: _move(
          id: 'hard_press',
          type: 'steel',
          battleEngineMethod: 's_hard_press',
          power: 1,
        ),
        opponentCurrentHp: 25,
      );

      expect(
        _damage(wringOutFullTarget, moveId: 'wring_out'),
        greaterThan(_damage(wringOutLowTarget, moveId: 'wring_out')),
      );
      expect(
        _damage(hardPressFullTarget, moveId: 'hard_press'),
        greaterThan(_damage(hardPressLowTarget, moveId: 'hard_press')),
      );
    });

    test('s_electro_ball and s_gyro_ball resolve power from speed ratio', () {
      final electroFastUser = _runMove(
        playerMove: _move(
          id: 'electro_ball',
          type: 'electric',
          battleEngineMethod: 's_electro_ball',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        playerSpeed: 200,
        opponentSpeed: 40,
      );
      final electroSlowUser = _runMove(
        playerMove: _move(
          id: 'electro_ball',
          type: 'electric',
          battleEngineMethod: 's_electro_ball',
          power: 1,
          category: PsdkBattleMoveCategory.special,
        ),
        playerSpeed: 50,
        opponentSpeed: 100,
      );
      final gyroSlowUser = _runMove(
        playerMove: _move(
          id: 'gyro_ball',
          type: 'steel',
          battleEngineMethod: 's_gyro_ball',
          power: 1,
        ),
        playerSpeed: 25,
        opponentSpeed: 200,
      );
      final gyroFastUser = _runMove(
        playerMove: _move(
          id: 'gyro_ball',
          type: 'steel',
          battleEngineMethod: 's_gyro_ball',
          power: 1,
        ),
        playerSpeed: 200,
        opponentSpeed: 25,
      );

      expect(
        _damage(electroFastUser, moveId: 'electro_ball'),
        greaterThan(_damage(electroSlowUser, moveId: 'electro_ball')),
      );
      expect(
        _damage(gyroSlowUser, moveId: 'gyro_ball'),
        greaterThan(_damage(gyroFastUser, moveId: 'gyro_ball')),
      );
    });

    test('s_electro_ball keeps PSDK strict threshold boundaries', () {
      PsdkBattleTurnResult runElectroBallAtRatio({
        required int targetSpeed,
      }) {
        return _runMove(
          playerMove: _move(
            id: 'electro_ball',
            type: 'electric',
            battleEngineMethod: 's_electro_ball',
            power: 1,
            category: PsdkBattleMoveCategory.special,
          ),
          playerSpeed: 100,
          opponentSpeed: targetSpeed,
        );
      }

      // PSDK's Ruby table uses `first > ratio`, so exact thresholds fall into
      // the next lower bucket: 25/100 => 120 power, 33/100 => 80 power,
      // 50/100 => 60 power, 100/100 => 40 power.
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 24),
              moveId: 'electro_ball'),
          27);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 25),
              moveId: 'electro_ball'),
          22);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 32),
              moveId: 'electro_ball'),
          22);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 33),
              moveId: 'electro_ball'),
          15);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 49),
              moveId: 'electro_ball'),
          15);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 50),
              moveId: 'electro_ball'),
          12);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 99),
              moveId: 'electro_ball'),
          12);
      expect(
          _damage(runElectroBallAtRatio(targetSpeed: 100),
              moveId: 'electro_ball'),
          8);
    });

    test('s_flail keeps exact PSDK HP threshold boundaries', () {
      PsdkBattleTurnResult runFlailAtHp(int hp) {
        return _runMove(
          playerMove: _move(
            id: 'flail',
            battleEngineMethod: 's_flail',
            power: 1,
          ),
          playerCurrentHp: hp,
        );
      }

      // PSDK uses strict `>` thresholds: HP rate 70%, 35%, 20%, 10% and 4%
      // already belong to the stronger lower-HP bucket.
      expect(_damage(runFlailAtHp(71), moveId: 'flail'), 5);
      expect(_damage(runFlailAtHp(70), moveId: 'flail'), 8);
      expect(_damage(runFlailAtHp(36), moveId: 'flail'), 8);
      expect(_damage(runFlailAtHp(35), moveId: 'flail'), 15);
      expect(_damage(runFlailAtHp(21), moveId: 'flail'), 15);
      expect(_damage(runFlailAtHp(20), moveId: 'flail'), 19);
      expect(_damage(runFlailAtHp(11), moveId: 'flail'), 19);
      expect(_damage(runFlailAtHp(10), moveId: 'flail'), 27);
      expect(_damage(runFlailAtHp(5), moveId: 'flail'), 27);
      expect(_damage(runFlailAtHp(4), moveId: 'flail'), 36);
    });

    test('status-boosted power moves check the correct battler status', () {
      final healthyFacade = _runMove(
        playerMove: _move(
          id: 'facade',
          battleEngineMethod: 's_facade',
          power: 70,
        ),
      );
      final burnedFacade = _runMove(
        playerMove: _move(
          id: 'facade',
          battleEngineMethod: 's_facade',
          power: 70,
        ),
        playerMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final healthyParade = _runMove(
        playerMove: _move(
          id: 'infernal_parade',
          type: 'ghost',
          battleEngineMethod: 's_infernal_parade',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final targetStatusParade = _runMove(
        playerMove: _move(
          id: 'infernal_parade',
          type: 'ghost',
          battleEngineMethod: 's_infernal_parade',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.sleep,
      );
      final targetStatusBitterMalice = _runMove(
        playerMove: _move(
          id: 'bitter_malice',
          type: 'ghost',
          battleEngineMethod: 's_bitter_malice',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.paralysis,
      );

      expect(
        _damage(burnedFacade, moveId: 'facade'),
        greaterThan(_damage(healthyFacade, moveId: 'facade')),
      );
      expect(
        _damage(targetStatusParade, moveId: 'infernal_parade'),
        greaterThan(_damage(healthyParade, moveId: 'infernal_parade')),
      );
      expect(
        _damage(targetStatusBitterMalice, moveId: 'bitter_malice'),
        _damage(targetStatusParade, moveId: 'infernal_parade'),
      );
    });

    test('s_hex and s_venoshock double final damage for PSDK status rules', () {
      final normalHex = _runMove(
        playerMove: _move(
          id: 'hex',
          type: 'ghost',
          battleEngineMethod: 's_hex',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final burnedHex = _runMove(
        playerMove: _move(
          id: 'hex',
          type: 'ghost',
          battleEngineMethod: 's_hex',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final burnedVenoshock = _runMove(
        playerMove: _move(
          id: 'venoshock',
          type: 'poison',
          battleEngineMethod: 's_venoshock',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.burn,
      );
      final poisonedVenoshock = _runMove(
        playerMove: _move(
          id: 'venoshock',
          type: 'poison',
          battleEngineMethod: 's_venoshock',
          power: 65,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentMajorStatus: PsdkBattleMajorStatus.poison,
      );

      expect(_damage(burnedHex, moveId: 'hex'),
          _damage(normalHex, moveId: 'hex') * 2);
      expect(
        _damage(poisonedVenoshock, moveId: 'venoshock'),
        _damage(burnedVenoshock, moveId: 'venoshock') * 2,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  int playerSpeed = 100,
  int opponentSpeed = 50,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        currentHp: playerCurrentHp,
        speed: playerSpeed,
        move: playerMove,
        majorStatus: playerMajorStatus,
      ),
      opponent: _combatant(
        id: 'opponent',
        currentHp: opponentCurrentHp,
        speed: opponentSpeed,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
        majorStatus: opponentMajorStatus,
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int currentHp,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    // Keep fixture types away from the move types so the assertions isolate the
    // PSDK formulas instead of accidentally measuring STAB.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[move],
    majorStatus: majorStatus,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 0,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
```
