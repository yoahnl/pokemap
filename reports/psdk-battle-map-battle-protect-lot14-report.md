# Rapport Lot 14 - map_battle - Protect PSDK minimal

Date: 2026-04-24

## Objectif

Porter un premier effet PSDK `Protect` dans la nouvelle voie de combat clean architecture de `packages/map_battle`, sans toucher aux animations ni au runtime Flutter.

Le lot couvre:

- un stockage d'effets de combatant cote PSDK;
- le flag de move `protectable`;
- le behavior `s_protect`;
- le blocage d'une attaque adverse dans le meme tour;
- l'expiration de Protect en fin de tour;
- un scenario CLI `protect` exploitable par les sub-agents;
- les regressions PSDK critiques: Protect echoue si l'utilisateur agit dernier, et Protect est prioritaire sur l'immunite de type pour les coups protectable.

## Audit initial

Sources inspectees:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_data.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/test/psdk_protect_effect_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`

Constat:

- la voie PSDK avait deja l'ordre de tour, PP, timeline, accuracy, type damage, status, secondary effects et hooks;
- elle n'avait pas encore de pile d'effets persistante entre deux actions du meme tour;
- les moves n'exposaient pas encore un flag `protectable`;
- le runner ne transmettait pas de contexte indiquant si une action est la derniere action executable du tour;
- le CLI n'avait pas de fixture dediee a Protect.

## Sub-agents et passes

- Audit / Architecture: sub-agent Dewey. Il a valide le scope et a signale deux trous avant stabilisation: status moves non bloques par Protect et absence de flag `protectable`. Les deux points ont ete corriges et couverts par tests.
- Critique finale intermediaire: sub-agent Galileo. Verdict initial non pret, deux findings importants:
  - Protect reussissait encore si l'utilisateur agissait dernier;
  - l'immunite de type pouvait masquer un blocage par Protect.
  Les deux findings ont ete reproduits par tests rouges puis corriges.
- Critique finale apres correction: sub-agent Halley. Verdict pret, aucun finding bloquant ou important. Points verifies: echec dernier a agir, priorite Protect avant immunite, architecture pure Dart, couverture tests et CLI.

## Fichiers modifies ou crees

### Modifies

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
  - ajout de `PsdkBattleEffectIds`;
  - ajout de `PsdkBattleEffectStack`;
  - ajout du champ `effects` dans `PsdkBattleCombatantSetup` et `PsdkBattleCombatant`;
  - propagation dans `fromSetup` et `copyWith`.

- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
  - propagation des effets PSDK vers `BattleEffectStack` dans les factories clean.

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`
  - ajout du flag `protectable`, par defaut `true`;
  - propagation dans `copyWith`.

- `packages/map_battle/lib/src/domain/move/battle_move_data.dart`
  - mapping `PsdkBattleMoveData.protectable` vers `BattleMoveFlags.protectable`;
  - mapping inverse dans `BattleMoveDefinition.psdkMove`.

- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
  - ajout de `BattleMoveFailureReason.protected`;
  - serialisation JSON `protected`.

- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
  - ajout du contexte `isLastActionOfTurn`.

- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
  - propagation de `isLastActionOfTurn` entre contexte PSDK et contexte clean.

- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
  - boucle d'actions indexee;
  - calcul `_hasRunnableActionAfter`;
  - passage de `isLastActionOfTurn`;
  - nettoyage des effets turn-scoped apres resolution du tour.

- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
  - enregistrement de `s_protect`;
  - implementation de `_resolveProtect`;
  - integration du blocage Protect dans le precheck de cibles;
  - priorite Protect avant immunite de type;
  - respect de `protectable == false`.

- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
  - ajout du scenario CLI `protect`;
  - fixture Protect vs Tackle;
  - support d'un `opponentMove` specifique dans le setup du CLI.

- `packages/map_battle/test/psdk_battle_cli_test.dart`
  - test JSON du scenario CLI `protect`.

### Crees

- `packages/map_battle/test/psdk_protect_effect_test.dart`
  - suite dediee a Protect PSDK minimal.

- `reports/psdk-battle-map-battle-protect-lot14-report.md`
  - present rapport.

### Supprimes

- Aucun fichier supprime.

## Logique mise en place

### Effet combatant

`Protect` est stocke sur le combatant PSDK via un effet id immutable:

```dart
final class PsdkBattleEffectIds {
  const PsdkBattleEffectIds._();

  static const String protect = 'protect';
}

class PsdkBattleEffectStack {
  PsdkBattleEffectStack({
    Iterable<String> values = const <String>[],
  }) : _values = List<String>.unmodifiable(values.map(_requireEffectId));

  const PsdkBattleEffectStack.empty() : _values = const <String>[];

  PsdkBattleEffectStack add(String effectId) { ... }
  PsdkBattleEffectStack remove(String effectId) { ... }
  PsdkBattleEffectStack clearTurnScopedEffects() {
    return remove(PsdkBattleEffectIds.protect);
  }
}
```

Pourquoi:

- PSDK attache les effets de protection au Pokemon / battler;
- le moteur Dart doit garder cet effet visible entre deux actions du meme tour;
- l'objet reste immutable pour eviter les mutations externes d'un snapshot public.

### Behavior `s_protect`

`s_protect` est resolu par le registry statique. Il echoue si le lanceur agit dernier, puis passe par la procedure commune avant de poser l'effet:

```dart
BattleMoveBehaviorResolution _resolveProtect(
    BattleMoveBehaviorContext context) {
  if (context.isLastActionOfTurn) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }

  final common = _prepareMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final protectedSlot = common.psdkTargets.single;
  final protectedBattler = common.state.battlerAt(protectedSlot);
  final nextState = common.state.replaceBattler(
    protectedSlot,
    protectedBattler.copyWith(
      effects: protectedBattler.effects.add(PsdkBattleEffectIds.protect),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: common.rng,
    events: common.events,
  );
}
```

Pourquoi:

- PSDK `Protect#move_usable_by_user` refuse Protect si l'utilisateur attaque dernier;
- le refus reste un vrai echec de move, avec PP deja depense par le runner comme dans le flux actuel;
- si Protect reussit, les actions plus lentes du meme tour peuvent observer l'effet.

### Ordre d'action

Le runner transmet l'information:

```dart
isLastActionOfTurn: !_hasRunnableActionAfter(
  actions,
  actionIndex,
),
```

`_hasRunnableActionAfter` ignore les actions ulterieures dont le user ou la cible est deja KO.

Pourquoi:

- Protect ne doit pas se poser "pour rien" apres toutes les attaques adverses du tour;
- cette information doit rester dans le contexte du behavior, pas dans un hack specifique au move id.

### Blocage avant immunite de type

Le precheck de cible verifie Protect avant l'immunite de type:

```dart
for (final targetRef in targets) {
  if (_isBlockedByProtect(execution, targetRef)) {
    failureReason = BattleMoveFailureReason.protected;
    execution.timeline.add(
      BattleMoveFailedTimelineEvent(
        turn: execution.turn,
        user: execution.user,
        target: targetRef,
        moveId: execution.move.id,
        reason: BattleMoveFailureReason.protected.jsonName,
      ),
    );
    continue;
  }

  if (shouldCheckTypeImmunity) {
    ...
  }
  unblockedTargets.add(targetRef);
}
```

Pourquoi:

- un coup qui vise une cible protegee doit exposer le resultat `protected`;
- l'immunite de type ne doit pas produire une timeline trompeuse quand Protect est deja actif;
- les moves `protectable: false` traversent volontairement le bouclier.

### Nettoyage fin de tour

Le runner appelle `_clearTurnScopedEffects()` apres la resolution du tour et avant l'exposition du `BattlePublicState`.

Pourquoi:

- Protect doit etre visible pendant le tour courant;
- il ne doit pas survivre au tour suivant dans ce lot minimal.

## Tests TDD

Tests rouges observes pendant le lot:

- Premier rouge: les tests `psdk_protect_effect_test.dart` / `psdk_battle_cli_test.dart` echouaient car les contrats `effects`, `PsdkBattleEffectStack`, `protectable` et le scenario CLI `protect` n'existaient pas encore.
- Rouge critique apres relecture:
  - `Protect failure is visible when the user acts last`: `lastSuccessfulMoveId` valait encore `protect`;
  - `Protect blocks before type immunity reports a misleading immune`: la timeline contenait `move_immune` au lieu de `move_failed protected`.

Tests crees ou etendus:

- `s_protect blocks a slower incoming attack during the same turn`;
- `protect expires before the next turn`;
- `a pre-seeded protect effect is immutable and cleared at turn end`;
- `Protect blocks an incoming status move that targets the user`;
- `Protect failure is visible when the user acts last`;
- `Protect blocks before type immunity reports a misleading immune`;
- `a non-protectable move can pass through Protect`;
- `prints a Protect scenario that blocks an incoming move`.

## Commandes de validation

Toutes les commandes ont ete lancees dans `packages/map_battle`, sauf indication contraire.

```bash
dart test test/psdk_protect_effect_test.dart
```

Resultat: `+7: All tests passed!`

```bash
dart test test/psdk_protect_effect_test.dart test/psdk_battle_cli_test.dart test/psdk_move_hooks_test.dart test/psdk_pp_history_test.dart test/psdk_move_procedure_test.dart test/psdk_move_registry_test.dart test/psdk_type_damage_test.dart test/psdk_engine_smoke_test.dart
```

Resultat: `+51: All tests passed!`

```bash
dart analyze
```

Resultat: `No issues found!`

```bash
dart test
```

Resultat: `+296: All tests passed!`

```bash
dart run bin/psdk_battle_cli.dart --scenario protect --format json
```

Resultat utile:

```json
{
  "outcome": "ongoing",
  "turns": 1,
  "playerHp": 100,
  "opponentHp": 100,
  "events": [
    {"kind": "move_pp_spent", "moveId": "protect", "remainingPp": 34},
    {"kind": "move_declared", "moveId": "protect"},
    {"kind": "animation_cue", "moveId": "protect"},
    {"kind": "move_pp_spent", "moveId": "opponent_tackle", "remainingPp": 34},
    {"kind": "move_declared", "moveId": "opponent_tackle"},
    {"kind": "move_failed", "moveId": "opponent_tackle", "reason": "protected"}
  ]
}
```

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Resultat: `Generated: /tmp/pokemon_project_psdk_battle_cli`

```bash
/tmp/pokemon_project_psdk_battle_cli --scenario protect --format json
```

Resultat: meme scenario Protect que la version source, avec `playerHp=100` et `reason=protected`.

Depuis la racine repo:

```bash
git diff --check
```

Resultat: aucune sortie, donc pas d'erreur whitespace.

## Etat git

Le workspace etait deja tres sale a cause des lots precedents et de modifications hors scope (`map_core`, `map_editor`, `.idea`, rapports precedents). Aucun revert n'a ete fait.

Fichiers du lot courant a prendre en compte:

- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_move.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_data.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_prevention.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/psdk/application/psdk_battle_move_behavior.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/test/psdk_protect_effect_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `reports/psdk-battle-map-battle-protect-lot14-report.md`

## Limitations assumees

- Pas de success-rate decay de Protect pour les usages consecutifs.
- Pas encore de variantes PSDK comme Endure, Detect, Spiky Shield, Baneful Bunker, King's Shield.
- Pas encore de callbacks d'effet riches type `on_move_ability_immunity`; le lot pose seulement le minimum necessaire au blocage.
- Pas encore de modele multi-cibles complet. Le precheck est structure pour plusieurs cibles, mais le moteur courant reste essentiellement singles.
- Les flags `protectable` sont supportes par le DTO et le moteur, mais l'import Studio complet devra les alimenter depuis les donnees PSDK dans un lot dedie.
- Le CLI reste une fixture embarquee, pas un lecteur de fichier de data PSDK.

## Critique finale

Verdict: pret pour continuer au lot suivant.

Points solides:

- Protect a maintenant une place domain claire et testee dans l'etat PSDK.
- Le behavior `s_protect` passe par la procedure clean existante et ne contourne pas PP, timeline ou history.
- Les deux ecarts PSDK trouves en critique finale sont couverts par tests regressifs.
- Le scenario CLI permet aux sub-agents de tester rapidement le comportement sans Flutter.
- La validation package complete est verte.

Risque residuel principal:

- La future generalisation des effets PSDK devra remplacer la pile d'ids par des objets/evenements plus riches, sans casser la surface ajoutee ici. Le design actuel isole volontairement cette transition.

## Prochaine suite conseillee

Lot 15 recommande: porter un premier effet de prevention utilisateur / condition d'action PSDK plus general que Protect, par exemple paralysis / sleep gate ou charge-turn, en reutilisant les hooks et le contexte d'ordre de tour existants.
