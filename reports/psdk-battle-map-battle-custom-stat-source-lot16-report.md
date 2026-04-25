# PSDK Battle - Lot 16 Custom Stat Source Moves

## Resume executif

Ce lot ajoute dans `packages/map_battle` un port Dart des familles Pokemon SDK dont la formule de degats garde la puissance normale mais remplace les sources de stats :

- `s_body_press` : offense = Defense de l'utilisateur.
- `s_foul_play` : offense = Attack de la cible.
- `s_psyshock` : offense = Special Attack de l'utilisateur, defense = Defense de la cible.
- `s_custom_stats_based` : support limite et explicite de `psyshock` et `secret_sword`.

Le lot garde ces methodes en statut `partial` dans la matrice PSDK, car les hooks complets d'abilities/items/effects PSDK ne sont pas encore portes.

## Scope confirme

Inclus :

- Port des formules de source de stat pour Body Press, Foul Play, Psyshock et Secret Sword.
- Integration dans `StaticBasicMoveRegistry`.
- Extension du calculateur de degats via des resolvers critiques-aware.
- Helper de stats PSDK avec aliases Ruby (`atk`, `dfe`, `ats`, `dfs`, `spd`).
- Scenario CLI `custom_stat`.
- Tests TDD dedies, tests CLI et verrouillage manifest.
- Regeneration des matrices de porting.

Hors scope volontaire :

- Abilities PSDK (`Unaware`, `Guts`, `Skill Link`, etc.).
- Items PSDK et modifiers de terrain/effects.
- Burn/Guts comme modifier offensif complet.
- `Sniper` et tout modificateur critique avance.
- Support generique de tous les symboles possibles de `s_custom_stats_based`.

## Audit initial

Prompt audite : continuer la migration PSDK, en faisant plusieurs lots si possible. La continuite du repo montrait que le bon prochain lot n'etait pas un nouveau grand pan runtime, mais une famille de moves PSDK deja isolee par les rapports precedents : les attaques a source de stat custom.

Fichiers et contrats identifies :

- `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart` : formule de degats centralisee.
- `packages/map_battle/lib/src/domain/move/behaviors/variable_power_move_behavior.dart` : precedent pour les moves PSDK qui injectent un override par hit.
- `packages/map_battle/lib/src/domain/move/behaviors/fixed_damage_move_behavior.dart` : precedent pour une behavior dediee au lieu d'un callback ad hoc.
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart` : etat immutable des combattants, stats et stat stages.
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart` : registre actuel des `battleEngineMethod`.
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart` : CLI smoke existant pour sous-agents et validation.
- `packages/map_battle/tool/extract_psdk_move_registry.dart` : source de verite pour manifest/matrice.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 BodyPress.rb`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 FoulPlay.rb`.
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 CustomStatsBased.rb`.

Risques principaux :

- Confondre une variation de puissance avec une variation de stat source.
- Perdre la regle critique PSDK differente selon la stat offensive/defensive.
- Marquer trop tot ces moves comme `ported` alors que les modifiers abilities/items/effects manquent.
- Casser les moves existants en modifiant la formule commune au lieu d'ajouter un override etroit.

Decision d'architecture :

- Ajouter `CustomStatSourceMoveBehavior` dedie.
- Ajouter a `BattleMoveDamageOverrides` des resolvers `bool isCritical -> int` pour calculer les stats apres resolution critique.
- Garder `BattleMoveDamageCalculator` proprietaire de la formule commune, du critique, du random roll, du STAB et de l'efficacite.

## Etat git initial

Etat au demarrage de cette reprise : worktree deja fortement dirty par les lots precedents et d'autres chantiers utilisateur/agents.

Constat important :

- Plusieurs fichiers `map_core` et `map_editor` etaient deja modifies.
- De nombreux fichiers `packages/map_battle` et `reports/` etaient deja non suivis, issus des lots PSDK precedents.
- Aucune commande destructive n'a ete lancee.
- Aucun changement non lie n'a ete revert.

## Sub-agents et passes nommees

### Sub-agent Audit / Architecture - Euclid

Verdict :

- Porter maintenant `s_body_press`, `s_foul_play`, `s_psyshock`.
- Porter `s_custom_stats_based` seulement pour les symboles connus `psyshock` et `secret_sword`.
- Garder le statut `partial`.
- Details PSDK :
  - Body Press : offense = `user.dfe_basis`, stage Defense utilisateur, mais critique => stage offensive ignoree.
  - Foul Play : offense = Attack cible, stage Attack cible, mais critique => stage offensive ignoree.
  - Psyshock / Secret Sword : Special Attack utilisateur contre Defense cible.
  - Critique Psyshock : ignorer les baisses SpA, garder les boosts.
  - Defense cible critique : ignorer les boosts defensifs, garder les drops.

### Sub-agent Audit / Architecture - Aquinas

Verdict :

- Ne pas etendre `VariablePowerMoveBehavior`.
- Ajouter une behavior dediee `CustomStatSourceMoveBehavior`.
- Ajouter un seam `BattleMoveDamageOverrides` critique-aware plutot qu'une mutation du move catalog.
- Ajouter des tests exacts autour des valeurs de degats.

### Passe Implementation

Actions :

- Ajout du resolver de stats dans `BattleMoveDamageOverrides`.
- Ajout de `PsdkBattleStats.valueOf`, `PsdkBattleStatStages.effectiveValue` et `PsdkBattleCombatant.effectiveStat`.
- Creation de `CustomStatSourceMoveBehavior`.
- Enregistrement dans `createStaticBasicMoveRegistry`.
- Ajout scenario CLI `custom_stat`.
- Mise a jour extracteur/matrice/manifest.

### Passe Tests

TDD applique :

- RED `custom_stat_source_test.dart` : les 8 tests echouaient initialement sur `UnsupportedBattleMoveBehavior`.
- RED `psdk_battle_cli_test.dart` : le scenario `custom_stat` echouait initialement sur scenario inconnu.
- GREEN apres implementation et regeneration du manifest.

### Passe Build / Validation

Commandes lancees et resultats exacts :

- `dart test test/psdk_move_families/custom_stat_source_test.dart` => `+8: All tests passed!`
- `dart test test/psdk_battle_cli_test.dart` => `+13: All tests passed!`
- `dart test test/psdk_registry_manifest_test.dart` => `+11: All tests passed!`
- `dart analyze` => `No issues found!`
- `dart test` => `+339: All tests passed!`
- `dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_check` => `Generated: /tmp/psdk_battle_cli_check`
- `dart run bin/psdk_battle_cli.dart --scenario custom_stat --format json` => `opponentHp: 71`, damage `body_press: 29`
- `dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_check` => `Generated: /tmp/extract_psdk_move_registry_check`
- `dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_check` => `Generated: /tmp/extract_psdk_effect_matrix_check`
- `dart format --set-exit-if-changed ...` => `Formatted 9 files (0 changed)`
- `git diff --check` => exit code 0, aucun whitespace error.

### Sub-agent Critique finale - Descartes

Verdict :

- Aucun blocant.
- Les regles critiques demandees sont respectees.
- Le registre cable bien les quatre comportements.
- Le CLI expose un scenario utile.
- Le manifest marque bien les familles en `partial`, pas `ported`.
- Point mineur signale : ajouter un cas dedie pour Defense cible boost/drop sur critique.

Action prise apres critique :

- Ajout de deux assertions dans `custom_stat_source_test.dart` :
  - target Defense +2 sur critique reste ignoree => degat `23`.
  - target Defense -2 sur critique est conservee => degat `44`.

## Fichiers modifies / crees

### `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`

Zones modifiees :

- Ajout de `typedef BattleMoveStatResolver = int Function(bool isCritical);`
- Ajout de `offensiveStatResolver` et `defensiveStatResolver` dans `BattleMoveDamageOverrides`.
- Ajout de guards `assert` pour interdire un override statique et un resolver simultanes.
- La formule commune resolve maintenant le critique avant de demander les stats overridees.

Raison :

- Les familles Body Press / Foul Play / Psyshock dependent du statut critique pour savoir quels stat stages ignorer.

Impact attendu :

- Aucun impact pour les moves existants qui utilisent `power`, `offensiveStat` ou `defensiveStat` statiques.
- Nouveau seam pour les moves PSDK dont les stats dependent du critique.

### `packages/map_battle/lib/src/domain/move/behaviors/custom_stat_source_move_behavior.dart`

Statut : fichier cree.

Classes/fonctions :

- `CustomStatSourceMoveBehavior.bodyPress`
- `CustomStatSourceMoveBehavior.foulPlay`
- `CustomStatSourceMoveBehavior.psyshock`
- `CustomStatSourceMoveBehavior.customStatsBased`
- `_offensiveStat`
- `_defensiveStat`
- `_guardSupportedCustomStatsDbSymbol`

Raison :

- Porter les familles PSDK dont les formules changent les stats, pas la puissance.

Impact attendu :

- `s_body_press`, `s_foul_play`, `s_psyshock`, `s_custom_stats_based` deviennent executables par le moteur PSDK Dart.

Contenu complet :

```dart
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _CustomStatSourceKind {
  bodyPress,
  foulPlay,
  psyshock,
  customStatsBased,
}

/// Ports PSDK moves that keep the normal damage formula but swap stat sources.
///
/// Ruby PSDK implements these as subclasses overriding `calc_sp_atk_basis` and
/// `calc_atk_stat_modifier`, not as dynamic-power moves. This behavior keeps
/// that boundary: it resolves the exact offensive/defensive stats for one hit,
/// then delegates the rest of damage, RNG, STAB, type and secondary effects to
/// the shared calculator/pipeline.
final class CustomStatSourceMoveBehavior implements BattleMoveBehavior {
  const CustomStatSourceMoveBehavior.bodyPress()
      : battleEngineMethod = 's_body_press',
        _kind = _CustomStatSourceKind.bodyPress;

  const CustomStatSourceMoveBehavior.foulPlay()
      : battleEngineMethod = 's_foul_play',
        _kind = _CustomStatSourceKind.foulPlay;

  const CustomStatSourceMoveBehavior.psyshock()
      : battleEngineMethod = 's_psyshock',
        _kind = _CustomStatSourceKind.psyshock;

  const CustomStatSourceMoveBehavior.customStatsBased()
      : battleEngineMethod = 's_custom_stats_based',
        _kind = _CustomStatSourceKind.customStatsBased;

  @override
  final String battleEngineMethod;
  final _CustomStatSourceKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    _guardSupportedCustomStatsDbSymbol(context);

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(
          offensiveStatResolver: (isCritical) => _offensiveStat(
            user: user,
            target: target,
            isCritical: isCritical,
          ),
          defensiveStatResolver: (isCritical) => _defensiveStat(
            target: target,
            isCritical: isCritical,
          ),
        ),
      ),
    );
    if (damageResult.damage <= 0) {
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
      amount: damageResult.damage,
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

  int _offensiveStat({
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    return switch (_kind) {
      _CustomStatSourceKind.bodyPress => user.effectiveStat(
          'defense',
          // PSDK BodyPress returns stage modifier 1 on critical hit, ignoring
          // both positive Defense boosts and negative Defense drops.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.foulPlay => target.effectiveStat(
          'attack',
          // PSDK FoulPlay also returns stage modifier 1 on critical hit, using
          // the target's raw Attack instead of any target Attack stage.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.psyshock ||
      _CustomStatSourceKind.customStatsBased =>
        user.effectiveStat(
          'specialAttack',
          // PSDK CustomStatsBased follows the base offensive critical rule:
          // negative drops are ignored, positive boosts are kept.
          ignoreNegativeStage: isCritical,
        ),
    };
  }

  int _defensiveStat({
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    // The three supported families route defense like a physical PSDK move:
    // target Defense is used, positive defensive boosts are ignored on crit,
    // and negative defensive drops still make the hit stronger.
    return target.effectiveStat(
      'defense',
      ignorePositiveStage: isCritical,
    );
  }

  void _guardSupportedCustomStatsDbSymbol(BattleMoveBehaviorContext context) {
    if (_kind != _CustomStatSourceKind.customStatsBased) {
      return;
    }
    final dbSymbol = context.move.dbSymbol.trim().toLowerCase();
    if (dbSymbol == 'psyshock' || dbSymbol == 'secret_sword') {
      return;
    }
    throw UnsupportedError(
      'Unsupported s_custom_stats_based dbSymbol "${context.move.dbSymbol}".',
    );
  }
}
```

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`

Zones modifiees :

- `PsdkBattleStats.valueOf`.
- `PsdkBattleStatStages.effectiveValue`.
- `PsdkBattleCombatant.effectiveStat`.
- `_normalizeStat` enrichi avec aliases PSDK.
- `_applyRegularStageMultiplier`.

Raison :

- Centraliser les aliases et la table de stages PSDK pour eviter de dupliquer ce calcul dans chaque move.

Impact attendu :

- Les moves custom stat-source peuvent demander une stat effective avec des flags critiques.
- Les futures families pourront reutiliser ce helper.

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Zones modifiees :

- Import de `custom_stat_source_move_behavior.dart`.
- Ajout des quatre constructors dans la liste du registre.

Raison :

- Rendre les `battleEngineMethod` executes par `PsdkBattleEngine`.

Impact attendu :

- Les moves importes depuis PSDK avec `s_body_press`, `s_foul_play`, `s_psyshock`, `s_custom_stats_based` ne tombent plus sur `UnsupportedBattleMoveBehavior`.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Zones modifiees :

- Nouveau scenario enum `customStat`.
- Parsing `custom_stat` et `custom-stat`.
- Message d'erreur mis a jour.
- Fixture `custom_stat` : Body Press, user Defense 100, no STAB, degat attendu 29.
- `_singleTurnSetup` accepte maintenant `playerStats`.

Raison :

- Permettre aux sous-agents et au thread principal de tester rapidement la formule sans Flutter.

Impact attendu :

- `dart run bin/psdk_battle_cli.dart --scenario custom_stat --format json` produit un JSON stable.

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones modifiees :

- Ajout dans `_knownDartBehaviors` :
  - `s_body_press` => `CustomStatSourceMoveBehavior.bodyPress`, `partial`.
  - `s_foul_play` => `CustomStatSourceMoveBehavior.foulPlay`, `partial`.
  - `s_psyshock` => `CustomStatSourceMoveBehavior.psyshock`, `partial`.
  - `s_custom_stats_based` => `CustomStatSourceMoveBehavior.customStatsBased`, `partial`.

Raison :

- Le port existe maintenant, mais n'est pas une parite complete PSDK.

Impact attendu :

- Manifest et matrice restent honnetes : `partial`, pas `ported`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Zones modifiees :

- Regeneration via extracteur.
- Les quatre familles passent de `missing` a `partial`.

Raison :

- Synchroniser le manifest avec le code executable.

Impact attendu :

- Les tests de manifest verrouillent le statut reel.

### `reports/psdk-move-porting-matrix.md`

Zones modifiees :

- Regeneration via extracteur.
- Counts :
  - `ported`: 16
  - `partial`: 10
  - `missing`: 290
- Lignes mises a jour :
  - `s_body_press`
  - `s_custom_stats_based`
  - `s_foul_play`
  - `s_psyshock`

### `reports/psdk-effect-porting-matrix.md`

Zones modifiees :

- Regeneration avec l'extracteur d'effets pour garder les matrices coherentes avec le lot.

## Tests crees ou modifies

### `packages/map_battle/test/psdk_move_families/custom_stat_source_test.dart`

Statut : fichier cree.

Couverture :

- Cas positif Body Press : Defense utilisateur utilisee comme offense.
- Cas positif Body Press : stages Defense utilises, stages Attack ignores.
- Cas positif Foul Play : Attack cible utilisee.
- Cas positif Foul Play : stage Attack cible utilise, stage Attack utilisateur ignore.
- Cas positif Psyshock : Special Attack utilisateur contre Defense cible.
- Cas critique :
  - Body Press ignore tous les stages offensifs Defense.
  - Foul Play ignore tous les stages offensifs Attack cible.
  - Psyshock ignore les drops SpA mais garde les boosts.
  - Defense cible boostee ignoree sur critique.
  - Defense cible baissee conservee sur critique.
- Cas garde-fou : `s_custom_stats_based` refuse un symbole inconnu avec `UnsupportedError`.
- Non-regression : les effets secondaires post-damage continuent de s'appliquer.

Contenu complet :

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK custom stat-source move families', () {
    test('s_body_press uses the user Defense as the offensive stat', () {
      final highDefense = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStats: _stats(
          attack: 10,
          defense: 100,
        ),
      );
      final lowDefense = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStats: _stats(
          attack: 100,
          defense: 20,
        ),
      );

      expect(_damage(highDefense, moveId: 'body_press'), 29);
      expect(_damage(lowDefense, moveId: 'body_press'), 6);
    });

    test('s_body_press uses Defense stages and ignores Attack stages', () {
      final neutral = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
      );
      final defenseBoost = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'dfe': 2,
        }),
      );
      final attackBoost = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'atk': 2,
        }),
      );

      expect(_damage(neutral, moveId: 'body_press'), 15);
      expect(_damage(defenseBoost, moveId: 'body_press'), 29);
      expect(_damage(attackBoost, moveId: 'body_press'), 15);
    });

    test('s_foul_play uses the target Attack as the offensive stat', () {
      final strongTarget = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStats: _stats(attack: 10),
        opponentStats: _stats(attack: 100),
      );
      final weakTarget = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStats: _stats(attack: 200),
        opponentStats: _stats(attack: 20),
      );

      expect(_damage(strongTarget, moveId: 'foul_play'), 34);
      expect(_damage(weakTarget, moveId: 'foul_play'), 7);
    });

    test('s_foul_play uses target Attack stages, not user Attack stages', () {
      final targetBoost = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );
      final userBoost = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );

      expect(_damage(targetBoost, moveId: 'foul_play'), 34);
      expect(_damage(userBoost, moveId: 'foul_play'), 18);
    });

    test('s_psyshock uses user Special Attack against target Defense', () {
      final highSpecialDefenseTarget = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
        opponentStats: _stats(
          defense: 50,
          specialDefense: 200,
        ),
      );
      final highDefenseTarget = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
        opponentStats: _stats(
          defense: 100,
          specialDefense: 50,
        ),
      );

      expect(_damage(highSpecialDefenseTarget, moveId: 'psyshock'), 29);
      expect(_damage(highDefenseTarget, moveId: 'psyshock'), 15);
    });

    test('custom stat-source moves keep PSDK critical stage rules', () {
      final bodyPressCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': -2,
        }),
      );
      final foulPlayCrit = _runMove(
        playerMove: _move(
          id: 'foul_play',
          battleEngineMethod: 's_foul_play',
          power: 95,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'attack': 2,
        }),
      );
      final psyshockCritWithDrop = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'specialAttack': -2,
        }),
      );
      final psyshockCritWithBoost = _runMove(
        playerMove: _move(
          id: 'psyshock',
          battleEngineMethod: 's_psyshock',
          power: 80,
          category: PsdkBattleMoveCategory.special,
          criticalRate: 4,
        ),
        playerStages: PsdkBattleStatStages(values: const <String, int>{
          'specialAttack': 2,
        }),
      );
      final targetDefenseBoostCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': 2,
        }),
      );
      final targetDefenseDropCrit = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          criticalRate: 4,
        ),
        opponentStages: PsdkBattleStatStages(values: const <String, int>{
          'defense': -2,
        }),
      );

      expect(_damage(bodyPressCrit, moveId: 'body_press'), 23);
      expect(_damage(foulPlayCrit, moveId: 'foul_play'), 26);
      expect(_damage(psyshockCritWithDrop, moveId: 'psyshock'), 23);
      expect(_damage(psyshockCritWithBoost, moveId: 'psyshock'), 44);
      expect(_damage(targetDefenseBoostCrit, moveId: 'body_press'), 23);
      expect(_damage(targetDefenseDropCrit, moveId: 'body_press'), 44);
    });

    test('s_custom_stats_based supports PSDK psyshock and secret_sword aliases',
        () {
      final psyshock = _runMove(
        playerMove: _move(
          id: 'psyshock',
          dbSymbol: 'psyshock',
          battleEngineMethod: 's_custom_stats_based',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
      );
      final secretSword = _runMove(
        playerMove: _move(
          id: 'secret_sword',
          dbSymbol: 'secret_sword',
          battleEngineMethod: 's_custom_stats_based',
          power: 80,
          category: PsdkBattleMoveCategory.special,
        ),
        playerStats: _stats(specialAttack: 100),
      );

      expect(_damage(psyshock, moveId: 'psyshock'), 29);
      expect(_damage(secretSword, moveId: 'secret_sword'), 29);
      expect(
        () => _runMove(
          playerMove: _move(
            id: 'unknown_custom',
            dbSymbol: 'unknown_custom',
            battleEngineMethod: 's_custom_stats_based',
            power: 80,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('custom stat-source moves keep the post-damage secondary chain', () {
      final result = _runMove(
        playerMove: _move(
          id: 'body_press',
          battleEngineMethod: 's_body_press',
          power: 80,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
      );

      final events = result.timeline.events.map((event) => event.kind).toList();
      expect(
          events,
          containsAllInOrder(<String>[
            'damage',
            'stat_stage_change',
          ]));
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        -1,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleStats? playerStats,
  PsdkBattleStats? opponentStats,
  PsdkBattleStatStages? playerStages,
  PsdkBattleStatStages? opponentStages,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        stats: playerStats ?? _stats(),
        statStages: playerStages,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        stats: opponentStats ?? _stats(),
        statStages: opponentStages,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
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
  required PsdkBattleStats stats,
  required PsdkBattleMoveData move,
  PsdkBattleStatStages? statStages,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    // Keep fixtures away from move types so formula assertions do not measure
    // STAB or type effectiveness by accident.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: stats,
    statStages: statStages,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleStats _stats({
  int attack = 50,
  int defense = 50,
  int specialAttack = 50,
  int specialDefense = 50,
  int speed = 50,
}) {
  return PsdkBattleStats(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String? dbSymbol,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 0,
  String battleEngineMethod = 's_basic',
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: dbSymbol ?? id,
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
    stageMods: stageMods,
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

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Zones modifiees :

- Ajout du test `prints a custom-stat scenario for PSDK stat-source formulas`.

Raison :

- Verifier que le CLI expose la nouvelle famille de formule.

Impact attendu :

- Les sous-agents peuvent lancer un scenario court et obtenir un JSON stable.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Zones modifiees :

- Ajout du test `tracks the Lot 16 custom stat-source slice`.

Raison :

- Verrouiller le statut `partial` et le mapping Dart des quatre methods.

Impact attendu :

- Si la matrice redevient `missing` ou pretend `ported`, le test echoue.

## Commandes de generation

```bash
cd packages/map_battle
dart run tool/extract_psdk_move_registry.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-move-porting-matrix.md --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-effect-porting-matrix.md
```

Resultat :

- Commandes terminees avec exit code 0.
- Matrice moves : 316 methods, 16 ported, 10 partial, 290 missing.

## Etat git final

Etat observe apres implementation :

- Worktree toujours dirty, comme au depart.
- Changements de ce lot concentres sur `packages/map_battle` et `reports`.
- Aucun revert ou nettoyage des changements preexistants.
- `git diff --check` exit code 0.

## Limites conservees

- `s_custom_stats_based` ne supporte que `psyshock` et `secret_sword`.
- Les quatre methods restent `partial`.
- Les modifiers globaux PSDK ne sont pas simules.
- Le CLI reste un harness embarque, pas encore un loader de fichiers projet.
- La matrice d'effets est regeneree mais ce lot ne porte pas de nouveaux effects.

## Auto-critique finale

Ce lot est volontairement petit dans le fond, mais il touche une zone sensible : la formule commune de degats. Le seam `BattleMoveStatResolver` est le point le plus important : il evite de mettre des conditions Body Press/Foul Play dans le calculateur tout en permettant de respecter les regles critiques. La contrepartie est qu'il faudra rester discipline : les prochains moves doivent continuer a ajouter des behaviors dediees, pas transformer `BattleMoveDamageOverrides` en sac universel.

Risque restant principal :

- Lorsque les abilities/items/effects seront portes, ces moves devront repasser de `partial` a `ported` seulement apres tests de parite avec les modifiers PSDK.

Prochaines etapes proposees :

- Porter le prochain groupe de moves a formule locale, probablement poids/vitesse manquants (`s_low_kick`, `s_heavy_slam`) ou variants multi-hit encore `missing`.
- Ajouter une couche de modifiers PSDK damage/effects avant de promouvoir les stat-source moves en `ported`.
- Etendre le CLI vers des fixtures chargeables pour comparer plus facilement plusieurs scenarios PSDK.
