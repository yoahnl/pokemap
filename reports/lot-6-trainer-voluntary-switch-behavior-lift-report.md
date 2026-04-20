# Lot 6 — Trainer Voluntary Switch Behavior Lift Report
## 1. Résumé Exécutif Honnête
Le lot 6 est **réussi** dans un périmètre volontairement petit et borné : les trainer battles peuvent maintenant produire un **switch volontaire adverse minimal** adossé à la difficulté trainer, sans rouvrir le runtime et sans transformer `battle_session.dart` en cerveau global d'IA. Le lot reste volontairement sobre : profil faible/legacy = aucun switch volontaire ; profil moyen = switch rare seulement si l'actif adverse est offensivement nul et qu'une réserve apporte un gain clair ; profil élevé = même logique mais avec une petite porte de sortie supplémentaire pour un actif très low HP. J'ai volontairement **refusé** d'ouvrir une IA riche, du type-pressure avancé, des scripts trainer/boss, un simulateur multi-tour ou un seam géant.

Le seam central reste `BattleOpponentPolicy`, qui a été élargi minimalement avec une décision `chooseVoluntarySwitch(...)` retournant soit `null`, soit une option de switch déjà jugée légale par la session. La session reste responsable de ce qui est légal ; la policy ne fait qu'arbitrer dans un cadre très étroit.
## 2. État Git Initial
Pré-gates réellement exécutés avant toute modification :

- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

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
Le worktree était donc **quasi propre** pour le lot 6, avec un seul untracked préexistant hors scope : `examples/.DS_Store`.
## 3. Méthode Réellement Suivie
1. Pré-gates git réels.
2. Audit ciblé des docs, reports et seams battle existants.
3. Classification explicite du périmètre pour résister à la dérive.
4. TDD : ajout d'abord de tests rouges unitaires policy + intégration session/scheduler.
5. Implémentation minimale sur le seam `BattleOpponentPolicy` et la consommation battle-locale dans `BattleSession`.
6. Review séparée par sub-agent ; prise en compte de deux findings réels.
7. Relance des validations ciblées et smoke runtime.
8. Rédaction du report avec annexes complètes des fichiers modifiés.
## 4. Périmètre Inclus / Exclu
### Inclus

- switch volontaire adverse minimal, trainer-only, piloté par la policy adverse
- garde-fous anti-thrash minimaux
- tests purs de policy et tests d'intégration session/timeline
- conservation du replacement forcé du lot 5
- smoke runtime pour s'assurer que le routing existant n'est pas cassé

### Exclu

- runtime / UI / authoring
- scripts trainer/boss
- targeting riche, doubles, multi-tour, type-pressure avancée
- framework générique d'IA
- refonte large de `battle_session.dart`
- refactor du scheduler
## 5. Classification Initiale Des Sujets
### `required_now`

- extension minimale de `BattleOpponentPolicy` pour arbitrer `fight vs voluntary switch` dans un cadre borné
- trainer-only voluntary switch
- garde-fou anti-thrash minimal
- tests policy rouges puis verts
- tests d'intégration session/timeline rouges puis verts
- rapport complet

### `fix_now_small`

- verrou explicite empêchant qu'une rich policy injectée manuellement dans un wild battle active le switch volontaire
- verrou cooldown après **tout** switch adverse du tour précédent, pas seulement après un switch volontaire
- mise à jour de quelques fixtures de tests lot 5 pour qu'elles restent centrées sur le replacement forcé et ne deviennent pas accidentellement des cas de switch volontaire

### `document_now_only`

- awkwardness légère du nom `BattleOpponentReplacementOption` réutilisé pour le seam de switch volontaire
- absence assumée de type matchup avancé
- absence assumée de mémoire IA longue

### `defer_not_lot6`

- type-pressure réelle
- heuristiques multi-tour
- scripts trainer/boss
- ciblage riche / doubles
- policy registry ou framework d'IA générique
## 6. Fichiers Lus
- `/Users/karim/Project/pokemonProject/docs/combat/battle-canonical-state-v3.1.md`
- `/Users/karim/Project/pokemonProject/docs/combat/battle-roadmap-canonical-v3.1.md`
- `/Users/karim/Project/pokemonProject/reports/lot-3-battle-opponent-policy-seam-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4-difficulty-routing-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4b-difficulty-authoring-ui-hardening-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4c-battle-ui-sprites-zone-backgrounds-corrective-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4d-battle-scene-responsive-staging-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4e-battle-ui-visual-lock-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-4f-portrait-battle-ui-hardening-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-5-trainer-difficulty-behavior-lift-report.md`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_opponent_policy.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_opponent_policy_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_switch_test.dart`
## 7. Fichiers Modifiés
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_opponent_policy.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_opponent_policy_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_switch_test.dart`

## 8. Fichiers Volontairement Non Touchés
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- tout `map_runtime` hors smoke de validation
- tout `map_core`, `map_editor`, `examples/playable_runtime_host`
- `battle_opponent_policy` routing runtime lot 4/5 : conservé tel quel, aucune nouvelle plomberie runtime
## 9. Validations Réellement Relancées
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test`
- `cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/phase_a_golden_battle_slice_smoke_test.dart`

## 10. Résultats Réellement Obtenus
- `dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart` : vert après implémentation ; rouge au début sur absence du seam `chooseVoluntarySwitch(...)` et sur les nouveaux comportements attendus
- `dart analyze` : vert (`No issues found!`)
- `dart test` complet dans `packages/map_battle` : vert
- `flutter test test/phase_a_golden_battle_slice_smoke_test.dart` dans `packages/map_runtime` : vert
## 11. Décisions Retenues / Rejetées Sujet Par Sujet
### Retenues

- étendre `BattleOpponentPolicy` d'un **troisième seam minimal** `chooseVoluntarySwitch(...)` plutôt que d'ouvrir un contrat géant
- garder la session responsable de la légalité (fight actions + switch options déjà filtrées)
- trainer-only gate côté session
- cooldown minimal basé sur “l'ennemi a switché au tour précédent”
- heuristique simple à score local, sans type chart avancée

### Rejetées

- refonte du scheduler
- seam de décision global “chooseEnemyTurnActionFamily” plus large
- policy/memory persistante multi-tour
- volontaire switch dans wild battles
- heuristique de type-pressure avancée
- scripts trainer/boss
## 12. Description Précise Du Comportement Voluntary Switch Retenu
### Profil faible / legacy (`null`, `1..3`)

- ne switch jamais volontairement
- continue à fight si possible
- conserve le fallback historique pour le replacement forcé

### Profil moyen (`4..7`)

- switch volontaire possible **uniquement** si l'actif adverse n'a **aucune vraie pression offensive** (`activeFightScore <= 0`)
- il faut une réserve utilisable avec un score offensif brut significativement meilleur
- il faut un gain clair (`bestReserveScore - activeStayScore >= 60`)
- sinon la policy reste en fight

### Profil élevé (`8..10`)

- switch volontaire possible si l'actif est soit à faible pression offensive (`<= 20` expected power), soit très low HP (`<= 25%`)
- la réserve est notée avec la même heuristique calculée que le replacement forcé lot 5 : pression offensive attendue + vitesse + santé
- il faut un gain clair (`bestReserveScore - activeStayScore >= 25`)
- sinon la policy reste en fight

### Comportement commun

- trainer battles uniquement
- l'option retournée doit appartenir à la liste des switches volontaires légaux fournie par la session
- si la policy retourne `null`, la session retombe sur `chooseFightAction(...)`
## 13. Justification Des Seams Choisis
Le seam central reste `BattleOpponentPolicy`. Le lot 5 avait déjà ouvert `chooseFightAction(...)` et `chooseReplacement(...)`. Le lot 6 ajoute seulement `chooseVoluntarySwitch(...)`, ce qui laisse :

- la session décider de ce qui est légal
- la policy arbitre seulement dans un très petit espace de décision
- le runtime inchangé
- le scheduler inchangé

J'ai volontairement **refusé** un seam plus gros du type “choisir la famille d'action ennemie au complet” parce qu'il aurait ouvert trop de surface trop tôt.
## 14. Garde-Fous Anti-Thrash Retenus
- `trainer-only` : aucun switch volontaire adverse dans les wild battles, même si une rich policy est injectée manuellement
- `didEnemySwitchLastTurn` : pas de reswitch immédiat après **tout** switch adverse du tour précédent
- `clearGainThreshold` : pas de switch si le gain est marginal
- `bestOptionScore > 0` : pas de switch vers une réserve elle-même nulle offensivement
- `activeIsLowPressure || activeIsLowHp` : pas de switch si l'actif a encore une bonne raison simple de rester
- contains-check en session : la policy ne peut pas synthétiser un switch illégal

Ces garde-fous vivent à deux endroits :

- dans `BattleOpponentPolicy` pour la partie heuristique de décision
- dans `BattleSession._resolveEnemyAction()` pour la partie légalité trainer-only / membership check
## 15. Incidents Rencontrés
- le shell local n'avait pas `dart` / `flutter` dans le `PATH` par défaut ; j'ai utilisé `/opt/homebrew/bin/dart` et `/opt/homebrew/bin/flutter` explicitement
- le reviewer séparé n'a pas répondu immédiatement ; il a fini par revenir avec deux findings réels que j'ai intégrés avant la validation finale
- plusieurs tests lot 5 de replacement forcé sont devenus accidentellement de bons cas de switch volontaire après l'implémentation ; j'ai ajusté les fixtures minimales pour conserver leur intention
## 16. Retour Des Sub-Agents
- explorer 1 : a confirmé que le plus petit seam propre était une extension de `BattleOpponentPolicy` plutôt qu'une refonte du scheduler ou de la session
- explorer 2 : a recommandé d'ancrer les preuves d'intégration sur la timeline, l'ordre des events de switch et la cohérence du tour suivant
## 17. Retour Du Reviewer Séparé
Review séparée obtenue, avec deux findings utiles :

1. **Trainer-only gate insuffisant** : une policy riche injectée manuellement dans un wild battle aurait pu activer le switch volontaire. Correction : garde explicite `setup.isTrainerBattle` dans `_resolveEnemyAction()`.
2. **Cooldown trop étroit** : la première version bloquait seulement un reswitch après switch volontaire, pas après tout switch adverse. Correction : `_didEnemySwitchLastTurn()` regarde désormais tout `BattleSwitchEventKind.switched` côté ennemi au tour précédent.
## 18. Critique Explicite Du Prompt Lui-Même
- le prompt est globalement très bon : il borne bien le lot, protège l'architecture et pousse vers une solution battle-locale honnête
- la demande “tests rouges puis verts” est saine, mais dans la pratique un seam nouveau casse d'abord à la compilation ; j'ai quand même respecté l'esprit TDD avec red/green réel
- l'exigence d'inclure le contenu complet de tous les fichiers touchés est utile pour l'audit, mais elle rend le report très lourd ; je l'ai respectée en excluant seulement l'auto-inclusion récursive du report lui-même
## 19. Autocritique Finale
- le lot est petit et propre, mais l'heuristique reste très simple ; il ne faut pas vendre ce comportement comme une IA contextuelle avancée
- le réemploi de `BattleOpponentReplacementOption` pour le voluntary switch garde le blast radius bas, mais le nom devient un peu moins élégant
- `battle_session.dart` a quand même pris une cinquantaine de lignes ; c'est acceptable ici, mais si un futur lot réouvre encore cette zone il faudra peut-être re-questionner la frontière
## 20. État Git Final Exact
### `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/src/battle_opponent_policy.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_opponent_policy_test.dart
 M packages/map_battle/test/battle_switch_test.dart
?? examples/.DS_Store
?? reports/lot-6-trainer-voluntary-switch-behavior-lift-report.md
```
### `git diff --stat`

```text
 .../map_battle/lib/src/battle_opponent_policy.dart | 143 ++++++++++++
 packages/map_battle/lib/src/battle_session.dart    |  53 +++++
 .../test/battle_opponent_policy_test.dart          | 243 +++++++++++++++++++++
 packages/map_battle/test/battle_switch_test.dart   | 214 +++++++++++++++++-
 4 files changed, 647 insertions(+), 6 deletions(-)
```
### `git ls-files --others --exclude-standard`

```text
examples/.DS_Store
reports/lot-6-trainer-voluntary-switch-behavior-lift-report.md
```
## 21. Checklist Finale
- [x] ai-je bien gardé le lot 6 petit et borné ?
- [x] ai-je bien ajouté un vrai switch volontaire adverse minimal ?
- [x] ai-je bien relié ce comportement à la difficulté trainer authorée via le routing existant ?
- [x] ai-je évité de transformer `battle_session.dart` en cerveau global ?
- [x] ai-je évité un framework d'IA générique ?
- [x] ai-je évité scripts trainer/boss ?
- [x] ai-je évité targeting riche / doubles / multi-tour ?
- [x] ai-je écrit des tests qui prouvent vraiment le comportement ?
- [x] ai-je gardé les wild battles sur un fallback honnête ?
- [x] ai-je été honnête sur ce qui est réellement supporté ?
- [x] ai-je relancé les validations utiles ?
- [x] ai-je utilisé des sub-agents si utile ?
- [x] ai-je tenté puis obtenu une review séparée ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés dans le rapport, hors récursion du report lui-même ?
- [x] ai-je évité toute écriture git interdite ?
## 22. Décision Finale Nette
Décision : **lot 6 réussi**.

Pourquoi :

- oui, l'ennemi trainer peut maintenant parfois switcher volontairement
- oui, ce comportement est réellement lié à la difficulté trainer déjà routée
- non, ce n'est pas une IA géante
- non, on n'a pas rouvert toute l'architecture
- oui, le comportement est testé en pur et en intégration
- oui, les wild battles et le legacy fallback restent honnêtes
## 23. Annexe — Contenu Complet Des Fichiers Modifiés
Conformément à la demande, cette annexe inclut le contenu complet de tous les fichiers modifiés du lot 6. Le report lui-même n'est pas ré-inclus récursivement.

### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_opponent_policy.dart

```dart
import 'battle_action.dart';
import 'battle_move.dart';
import 'battle_state.dart';

/// Seam battle-local de choix d'action adverse.
///
/// Ce contrat a été introduit au lot 3 pour sortir la sélection adverse de
/// `battle_session.dart`, puis légèrement élargi au lot 5 pour couvrir un
/// second cas très précis : le replacement adverse forcé après un K.O.
///
/// Cette extension reste volontairement bornée :
/// - elle garde la logique de difficulté hors de la session elle-même ;
/// - elle donne enfin un effet battle réel à la difficulté trainer ;
/// - mais sans ouvrir un arbitrage global entre familles d'actions, sans
///   scripts trainer/boss, sans switch volontaire intelligent et sans
///   targeting riche.
///
/// Frontières non négociables de ce seam :
/// - il ne choisit qu'entre des `BattleActionFight` déjà jugées légales ;
/// - il ne choisit un replacement qu'entre des réserves déjà jugées légales ;
/// - il ne reçoit ni `BattleSession`, ni queue, ni request, ni scheduler ;
/// - il ne gère toujours ni switch volontaire, ni `Run`, ni `Capture` ;
/// - il ne synthétise pas une nouvelle action : il doit retourner l'une des
///   options fight ou replacement qui lui sont fournies.
abstract interface class BattleOpponentPolicy {
  /// Choisit l'action fight adverse à jouer parmi les options déjà légales.
  ///
  /// Le contrat reste volontairement petit :
  /// - la session battle continue à décider quels moves sont encore utilisables
  ///   et à gérer les dead-ends explicites ;
  /// - la policy ne fait qu'arbitrer entre ces actions fight déjà prêtes ;
  /// - cela garde ce seam strictement dans le lot 3 au lieu de glisser vers
  ///   un mini-système d'IA générique.
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  });

  /// Choisit le replacement adverse forcé parmi les réserves déjà légales.
  ///
  /// Lot 5 garde cette question étroite pour éviter de dériver :
  /// - la session/scheduler continuent à décider quand un remplaçant est
  ///   requis ;
  /// - la policy n'arbitre pas "fight ou switch" ;
  /// - elle choisit seulement quel Pokémon déjà remplaçable doit entrer quand
  ///   l'adversaire est obligé de remplacer un K.O.
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  });

  /// Choisit éventuellement un switch volontaire adverse minimal.
  ///
  /// Le lot 6 garde ce seam volontairement borné :
  /// - la session continue à déterminer les moves fight légaux et les réserves
  ///   effectivement switchables ;
  /// - la policy ne reçoit qu'un snapshot local du combattant actif, ses
  ///   options fight et ses options de réserve ;
  /// - elle peut soit rester simple (`null` => continuer à fight), soit
  ///   retourner une des options de switch déjà légales qui lui sont fournies ;
  /// - aucun arbitrage global `Run/Capture`, aucun targeting riche, aucun
  ///   script trainer/boss n'est ouvert ici.
  ///
  /// `didEnemySwitchLastTurn` sert de garde-fou anti-thrash minimal :
  /// - il ne crée pas un état d'IA persistant ;
  /// - il permet simplement d'interdire un reswitch volontaire immédiat ;
  /// - si ce booléen vaut vrai, une policy saine doit préférer rester simple.
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  });
}

/// Option de replacement adverse déjà jugée légale par le moteur.
///
/// Ce type reste battle-local et volontairement pauvre :
/// - le scheduler filtre les réserves déjà K.O. avant d'arriver ici ;
/// - la policy reçoit juste l'index de réserve réellement switchable et le
///   combattant correspondant ;
/// - on évite ainsi de passer la session entière, la queue ou un contexte
///   d'IA surdimensionné pour un lot 5 qui doit rester petit.
final class BattleOpponentReplacementOption {
  const BattleOpponentReplacementOption({
    required this.reserveIndex,
    required this.combatant,
  });

  final int reserveIndex;
  final BattleCombatant combatant;
}

/// Route une difficulté produit `1..10` vers un petit nombre de profiles.
///
/// Ce helper existe pour garder le lot 4 honnête et borné :
/// - la difficulté visible produit reste bien un entier simple ;
/// - le battle-core ne crée pas pour autant 10 IA différentes ;
/// - le runtime peut demander une policy battle-local sans réinjecter la
///   logique de difficulté dans `battle_session.dart`.
///
/// Garde-fous explicites :
/// - `null` revient au comportement historique du dépôt ;
/// - les valeurs hors plage sont clampées à `[1, 10]` au lieu d'ouvrir ici un
///   nouveau système global de validation produit ;
/// - le mapping couvre maintenant `fight` et le replacement forcé ;
/// - mais il ne prépare toujours ni scripts trainer, ni switch volontaire,
///   ni targeting plus riche.
BattleOpponentPolicy battleOpponentPolicyForDifficulty(int? difficulty) {
  final clampedDifficulty = difficulty == null
      ? null
      : difficulty.clamp(1, 10);
  final profile = _BattleOpponentDifficultyProfile.fromProductDifficulty(
    clampedDifficulty,
  );
  return switch (profile) {
    _BattleOpponentDifficultyProfile.basic =>
      const BattleFirstLegalOpponentPolicy(),
    _BattleOpponentDifficultyProfile.aggressive =>
      const BattleHighestPowerOpponentPolicy(),
    _BattleOpponentDifficultyProfile.calculated =>
      const BattleHighestExpectedPowerOpponentPolicy(),
  };
}

/// Policy adverse par défaut du dépôt.
///
/// Le lot 3 garde volontairement un comportement équivalent à l'existant :
/// - aucune difficulté ;
/// - aucune heuristique de puissance, type ou statut ;
/// - aucune variabilité pseudo-aléatoire ;
/// - simplement le premier move fight encore légal et le premier remplaçant
///   encore utilisable.
///
/// Ce nom explicite évite deux mensonges :
/// - appeler cette classe `DefaultBattleOpponentPolicy` ferait masquer le fait
///   que son comportement réel est "premier move légal" ;
/// - appeler cela "IA" ferait croire à un système plus riche qu'il ne l'est.
final class BattleFirstLegalOpponentPolicy implements BattleOpponentPolicy {
  const BattleFirstLegalOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    if (legalFightActions.isEmpty) {
      throw StateError(
        'BattleFirstLegalOpponentPolicy requiert au moins une action fight légale.',
      );
    }
    return legalFightActions.first;
  }

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    if (legalReplacementOptions.isEmpty) {
      throw StateError(
        'BattleFirstLegalOpponentPolicy requiert au moins une option de replacement légale.',
      );
    }
    return legalReplacementOptions.first;
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    return null;
  }
}

/// Policy adverse "agressive" minimaliste du lot 4.
///
/// Pourquoi elle existe :
/// - donner au routing de difficulté un vrai profil intermédiaire ;
/// - sans demander plus de contexte battle que la liste des actions fight déjà
///   légales ;
/// - sans réimplémenter un calcul de dégâts complet ou une IA contextuelle.
///
/// Invariants de périmètre :
/// - seuls les moves offensifs avec `power > 0` marquent des points ;
/// - si toutes les actions sont purement de statut, on retombe sur le premier
///   move légal pour garder un comportement stable et lisible ;
/// - lot 5 lui ajoute un replacement forcé du même esprit :
///   choisir le remplaçant avec la pression offensive brute la plus forte ;
/// - aucune prise en compte du switch volontaire, du targeting ou de scripts
///   trainer n'est introduite ici.
final class BattleHighestPowerOpponentPolicy implements BattleOpponentPolicy {
  const BattleHighestPowerOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    return _pickBestFightAction(
      legalFightActions: legalFightActions,
      scoreMove: _rawPowerScore,
      emptyListError:
          'BattleHighestPowerOpponentPolicy requiert au moins une action fight légale.',
    );
  }

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    return _pickBestReplacementOption(
      legalReplacementOptions: legalReplacementOptions,
      scoreCombatant: _rawReplacementScore,
      emptyListError:
          'BattleHighestPowerOpponentPolicy requiert au moins une option de replacement légale.',
    );
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    return _chooseMinimalVoluntarySwitch(
      activeCombatant: activeCombatant,
      legalFightActions: legalFightActions,
      legalSwitchOptions: legalSwitchOptions,
      didEnemySwitchLastTurn: didEnemySwitchLastTurn,
      activeFightScore: _bestFightActionScore(
        legalFightActions: legalFightActions,
        moveScore: _rawPowerScore,
      ),
      switchOptionScore: _rawReplacementScore,
      clearGainThreshold: 60.0,
      lowPressureThreshold: 0.0,
      lowHpThreshold: 0.0,
    );
  }
}

/// Policy adverse "calculée" du lot 4.
///
/// Cette policy reste volontairement modeste :
/// - elle ne simule pas un tour complet ;
/// - elle ne lit pas `BattleSession` ;
/// - elle n'essaie pas d'estimer les hazards, statuts, switches ou scripts.
///
/// Elle fait uniquement mieux que le profil intermédiaire sur un point :
/// - pondérer la puissance offensive par la précision disponible ;
/// - et, au lot 5, préférer lors d'un replacement forcé un attaquant qui
///   reste à la fois menaçant, rapide et encore suffisamment sain ;
/// - ce qui donne un profil haut de gamme un peu plus dangereux sans
///   prétendre devenir une IA riche.
final class BattleHighestExpectedPowerOpponentPolicy
    implements BattleOpponentPolicy {
  const BattleHighestExpectedPowerOpponentPolicy();

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    return _pickBestFightAction(
      legalFightActions: legalFightActions,
      scoreMove: _expectedPowerScore,
      emptyListError:
          'BattleHighestExpectedPowerOpponentPolicy requiert au moins une action fight légale.',
    );
  }

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    return _pickBestReplacementOption(
      legalReplacementOptions: legalReplacementOptions,
      scoreCombatant: _calculatedReplacementScore,
      emptyListError:
          'BattleHighestExpectedPowerOpponentPolicy requiert au moins une option de replacement légale.',
    );
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    final activeFightScore = _bestFightActionScore(
      legalFightActions: legalFightActions,
      moveScore: _expectedPowerScore,
    );
    return _chooseMinimalVoluntarySwitch(
      activeCombatant: activeCombatant,
      legalFightActions: legalFightActions,
      legalSwitchOptions: legalSwitchOptions,
      didEnemySwitchLastTurn: didEnemySwitchLastTurn,
      activeFightScore: activeFightScore,
      switchOptionScore: _calculatedReplacementScore,
      clearGainThreshold: 25.0,
      lowPressureThreshold: 20.0,
      lowHpThreshold: 0.25,
    );
  }
}

enum _BattleOpponentDifficultyProfile {
  basic,
  aggressive,
  calculated;

  static _BattleOpponentDifficultyProfile fromProductDifficulty(
    int? difficulty,
  ) {
    if (difficulty == null) {
      return _BattleOpponentDifficultyProfile.basic;
    }
    if (difficulty <= 3) {
      return _BattleOpponentDifficultyProfile.basic;
    }
    if (difficulty <= 7) {
      return _BattleOpponentDifficultyProfile.aggressive;
    }
    return _BattleOpponentDifficultyProfile.calculated;
  }
}

BattleActionFight _pickBestFightAction({
  required List<BattleActionFight> legalFightActions,
  required double Function(BattleMove move) scoreMove,
  required String emptyListError,
}) {
  if (legalFightActions.isEmpty) {
    throw StateError(emptyListError);
  }

  // Le tie-break garde volontairement l'ordre des actions fournies par la
  // session. Cela évite d'ajouter une seconde couche de pseudo-random ou de
  // hiérarchie cachée alors que le lot 4 veut seulement router vers quelques
  // profils stables et lisibles.
  var bestAction = legalFightActions.first;
  var bestScore = scoreMove(bestAction.move);
  for (final action in legalFightActions.skip(1)) {
    final actionScore = scoreMove(action.move);
    if (actionScore > bestScore) {
      bestAction = action;
      bestScore = actionScore;
    }
  }
  return bestAction;
}

double _rawPowerScore(BattleMove move) {
  if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
    return 0.0;
  }
  return move.power.toDouble();
}

double _expectedPowerScore(BattleMove move) {
  final rawPower = _rawPowerScore(move);
  if (rawPower <= 0) {
    return 0.0;
  }
  final accuracyMultiplier =
      move.accuracy.isAlwaysHits ? 1.0 : move.accuracy.value / 100.0;
  return rawPower * accuracyMultiplier;
}

double _bestFightActionScore({
  required List<BattleActionFight> legalFightActions,
  required double Function(BattleMove move) moveScore,
}) {
  var bestScore = 0.0;
  for (final action in legalFightActions) {
    final candidateScore = moveScore(action.move);
    if (candidateScore > bestScore) {
      bestScore = candidateScore;
    }
  }
  return bestScore;
}

BattleOpponentReplacementOption _pickBestReplacementOption({
  required List<BattleOpponentReplacementOption> legalReplacementOptions,
  required double Function(BattleCombatant combatant) scoreCombatant,
  required String emptyListError,
}) {
  if (legalReplacementOptions.isEmpty) {
    throw StateError(emptyListError);
  }

  var bestOption = legalReplacementOptions.first;
  var bestScore = scoreCombatant(bestOption.combatant);
  for (final option in legalReplacementOptions.skip(1)) {
    final optionScore = scoreCombatant(option.combatant);
    if (optionScore > bestScore) {
      bestOption = option;
      bestScore = optionScore;
    }
  }
  return bestOption;
}

double _rawReplacementScore(BattleCombatant combatant) {
  return _bestDamagingMoveScore(
    combatant: combatant,
    moveScore: _rawPowerScore,
  );
}

double _calculatedReplacementScore(BattleCombatant combatant) {
  final expectedDamagePressure = _bestDamagingMoveScore(
    combatant: combatant,
    moveScore: _expectedPowerScore,
  );
  if (expectedDamagePressure <= 0) {
    return 0.0;
  }

  // Lot 5 reste volontairement petit :
  // - pas de lookahead multi-tour ;
  // - pas de type pressure complète ;
  // - pas de simulation de dégâts ;
  // - juste un léger lift crédible pour départager deux remplaçants déjà
  //   offensifs selon leur vitesse et leur marge de survie immédiate.
  final hpRatio =
      combatant.maxHp <= 0 ? 0.0 : combatant.currentHp / combatant.maxHp;
  final speedPressure = combatant.stats.speed * 0.35;
  final healthPressure = hpRatio * 40.0;
  return expectedDamagePressure + speedPressure + healthPressure;
}

BattleOpponentReplacementOption? _chooseMinimalVoluntarySwitch({
  required BattleCombatant activeCombatant,
  required List<BattleActionFight> legalFightActions,
  required List<BattleOpponentReplacementOption> legalSwitchOptions,
  required bool didEnemySwitchLastTurn,
  required double activeFightScore,
  required double Function(BattleCombatant combatant) switchOptionScore,
  required double clearGainThreshold,
  required double lowPressureThreshold,
  required double lowHpThreshold,
}) {
  if (didEnemySwitchLastTurn ||
      legalFightActions.isEmpty ||
      legalSwitchOptions.isEmpty) {
    return null;
  }

  final hpRatio = activeCombatant.maxHp <= 0
      ? 0.0
      : activeCombatant.currentHp / activeCombatant.maxHp;
  final activeIsLowPressure = activeFightScore <= lowPressureThreshold;
  final activeIsLowHp = lowHpThreshold > 0.0 && hpRatio <= lowHpThreshold;
  if (!activeIsLowPressure && !activeIsLowHp) {
    return null;
  }

  final activeStayScore = activeFightScore +
      (activeCombatant.stats.speed * 0.35) +
      (hpRatio * 40.0);

  BattleOpponentReplacementOption? bestOption;
  var bestOptionScore = 0.0;
  for (final option in legalSwitchOptions) {
    final optionScore = switchOptionScore(option.combatant);
    if (optionScore > bestOptionScore || bestOption == null) {
      bestOption = option;
      bestOptionScore = optionScore;
    }
  }

  if (bestOption == null || bestOptionScore <= 0.0) {
    return null;
  }
  if (bestOptionScore - activeStayScore < clearGainThreshold) {
    return null;
  }
  return bestOption;
}

double _bestDamagingMoveScore({
  required BattleCombatant combatant,
  required double Function(BattleMove move) moveScore,
}) {
  var bestScore = 0.0;
  for (final move in combatant.moves) {
    if (!move.hasUsablePp) {
      continue;
    }
    final candidateScore = moveScore(move);
    if (candidateScore > bestScore) {
      bestScore = candidateScore;
    }
  }
  return bestScore;
}

```
### /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart

```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
import 'battle_spikes.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_queue.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_opponent_policy.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

part 'battle_session_scheduler.dart';

const double _criticalHitMultiplier = 1.5;
const BattleConditionEngine _conditionEngine = BattleConditionEngine();

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
/// [rng] - Le seam RNG minimal utilisé par le hit pipeline.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(
  BattleSetup setup, {
  BattleRng rng = const BattleSeededRng(),
  BattleOpponentPolicy opponentPolicy =
      const BattleFirstLegalOpponentPolicy(),
}) {
  final player = _buildBattleCombatantFromData(setup.playerPokemon);
  final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
  final playerReserve = setup.playerReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);
  final enemyReserve = setup.enemyReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    playerSide: BattleSideState.player(
      active: player,
      reserve: playerReserve,
    ),
    enemySide: BattleSideState.enemy(
      active: enemy,
      reserve: enemyReserve,
    ),
    field: setup.fieldState,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
    opponentPolicy: opponentPolicy,
    pendingTurn: null,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

BattleCombatant _buildBattleCombatantFromData(
  BattleCombatantData data,
) {
  // On convertit tout le petit contrat battle d'un même bloc pour garantir
  // qu'aucune dimension déjà jugée honnête n'est reperdue lors du passage
  // setup -> state, y compris maintenant l'identité de lineup BE10.
  return BattleCombatant(
    speciesId: data.speciesId,
    lineupIndex: data.lineupIndex,
    level: data.level,
    currentHp: _clampHp(
      currentHp: data.currentHp,
      maxHp: data.maxHp,
    ),
    maxHp: data.maxHp,
    stats: data.stats,
    typing: data.typing,
    majorStatus: data.majorStatus,
    volatileState: data.volatileState,
    abilityId: data.abilityId,
    moves: data.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            majorStatusEffect: m.majorStatusEffect,
            selfVolatileStatus: m.selfVolatileStatus,
            weatherEffect: m.weatherEffect,
            pseudoWeatherEffect: m.pseudoWeatherEffect,
            setsStealthRock: m.setsStealthRock,
            setsSpikes: m.setsSpikes,
            breaksProtect: m.breaksProtect,
            requiresRecharge: m.requiresRecharge,
            chargeThenStrikeEffect: m.chargeThenStrikeEffect,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
          ),
        )
        .toList(growable: false),
  );
}

BattleSideId _opposingSideId(BattleSideId side) {
  return switch (side) {
    BattleSideId.player => BattleSideId.enemy,
    BattleSideId.enemy => BattleSideId.player,
  };
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [decisionRequest] expose la vraie requête de décision joueur
/// 3. [getAvailableChoices] reste disponible comme adaptateur de compatibilité
/// 4. [applyChoice] applique un choix et retourne une nouvelle session
/// 5. Répéter 2-4 jusqu'à ce que [state.isFinished] soit true
/// 6. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
    required this.opponentPolicy,
    required this.pendingTurn,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// RNG minimal du moteur battle.
  ///
  /// BE4 choisit de le garder sur la session plutôt que dans `BattleState` :
  /// - l'état observable du combat reste centré sur les combattants / outcomes ;
  /// - le RNG reste un détail de résolution, pas une donnée UI/runtime ;
  /// - mais il reste explicitement injectable et immutable.
  final BattleRng rng;

  /// Policy battle-locale de choix d'action adverse.
  ///
  /// Ce seam reste volontairement petit après les lots 3 à 5 :
  /// - la session continue à porter l'orchestration du tour, les actions
  ///   forcées et les dead-ends explicites ;
  /// - la policy ne choisit qu'entre des `BattleActionFight` déjà légales et,
  ///   depuis le lot 5, entre des options de replacement adverse déjà légales ;
  /// - la difficulté, les profils 1..10, les scripts trainer/boss et tout ce
  ///   qui touche switch volontaire/targeting restent volontairement hors
  ///   scope de ce champ pour éviter un faux framework d'IA.
  final BattleOpponentPolicy opponentPolicy;

  /// Continuation locale d'un tour déjà commencé mais suspendu pour demander
  /// un remplacement joueur en plein scheduling.
  ///
  /// Frontière H1 volontairement étroite :
  /// - ce seam n'ouvre pas un moteur général de tours interrompus ;
  /// - il sert uniquement à ne pas mentir quand un switch-in meurt aussitôt sur
  ///   Piège de Roc alors qu'une action adverse reste déjà en file ;
  /// - dès que le joueur choisit le remplacement, la queue reprend là où elle
  ///   s'était arrêtée.
  final _PendingTurnContinuation? pendingTurn;

  /// Requête de décision joueur explicitement exposée par le moteur.
  ///
  /// Phase C choisit ici le plus petit vrai progrès de fondation :
  /// - le moteur ne publie plus seulement une "liste plate de choix" ;
  /// - il expose désormais le type de demande courante :
  ///   tour libre, remplacement forcé, continuation forcée ou attente ;
  /// - runtime/UI peuvent donc consommer un contrat fort sans deviner le
  ///   sens du tour depuis les choix présents, le KO actif ou les volatiles.
  BattleDecisionRequest get decisionRequest => _buildDecisionRequest();

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// Compatibilité locale Phase C :
  /// - cette méthode reste volontairement publique pour limiter le blast
  ///   radius immédiat ;
  /// - mais elle n'est plus la source principale de vérité ;
  /// - elle dérive désormais directement de [decisionRequest].
  ///
  List<PlayerBattleChoice> getAvailableChoices() {
    return decisionRequest.allowedChoices;
  }

  BattleDecisionRequest _buildDecisionRequest() {
    const playerSideId = BattleSideId.player;
    const playerSlot = BattleSlotRef.active(BattleSideId.player);

    if (state.phase == BattlePhase.finished) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        side: playerSideId,
        slot: playerSlot,
        switchChoices: replacementChoices,
        reason: BattleForcedReplacementReason.activeFainted,
        faintedSpeciesId: state.player.speciesId,
      );
    }

    // Cas explicitement borné mais important :
    // - si l'actif est K.O. sans remplaçant valide et que la session n'est pas
    //   déjà terminée, on refuse d'inventer un faux tour libre ;
    // - le runtime voit alors un état "wait" bruyant au lieu d'un menu trompeur.
    if (state.player.isFainted) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.mustRecharge,
      );
    }

    // On construit maintenant explicitement le vrai tour libre :
    // - moves encore jouables ;
    // - switches volontaires valides ;
    // - issues sauvages éventuellement autorisées.
    final moveChoices = <PlayerBattleChoiceFight>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        moveChoices.add(PlayerBattleChoiceFight(i));
      }
    }
    final switchChoices = _availableVoluntarySwitchChoices();
    final captureChoice = !setup.isTrainerBattle && setup.allowCapture
        ? const PlayerBattleChoiceCapture()
        : null;
    final runChoice =
        !setup.isTrainerBattle ? const PlayerBattleChoiceRun() : null;

    if (moveChoices.isEmpty &&
        switchChoices.isEmpty &&
        captureChoice == null &&
        runChoice == null) {
      // Fermeture R1 volontairement bornée :
      // - on n'ouvre toujours pas `Struggle` ;
      // - on ne maquille pas non plus ce trou en "tour normal" avec un faux
      //   fallback ou un menu vide ;
      // - ce `wait` est donc un dead-end explicitement unsupported côté joueur,
      //   rendu visible au runtime/UI pour empêcher toute sur-promesse produit ;
      // - l'asymétrie avec l'ennemi reste assumée ici : l'ennemi n'expose pas
      //   de request publique et continue à échouer bruyamment par `StateError`
      //   quand le moteur n'a aucune action honnête à lui faire jouer.
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      side: playerSideId,
      slot: playerSlot,
      moveChoices: moveChoices,
      switchChoices: switchChoices,
      captureChoice: captureChoice,
      runChoice: runChoice,
    );
  }

  List<PlayerBattleChoiceSwitch> _availableForcedReplacementChoices() {
    if (!state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<PlayerBattleChoiceSwitch> _availableVoluntarySwitchChoices() {
    if (state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<int> _selectableReserveIndices(List<BattleCombatant> reserve) {
    final indices = <int>[];
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        indices.add(i);
      }
    }
    return List<int>.unmodifiable(indices);
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (combatant.isFainted) {
      return null;
    }

    final volatileState = combatant.volatileState;
    final pendingCharge = volatileState.pendingCharge;
    if (pendingCharge != null) {
      if (pendingCharge.moveIndex < 0 ||
          pendingCharge.moveIndex >= combatant.moves.length) {
        throw StateError(
          'Le combattant $combatantLabel porte un move chargé invalide (index ${pendingCharge.moveIndex}).',
        );
      }

      final chargedMove = combatant.moves[pendingCharge.moveIndex];
      if (chargedMove.id != pendingCharge.moveId ||
          chargedMove.chargeThenStrikeEffect == null) {
        throw StateError(
          'Le combattant $combatantLabel porte un état de charge incohérent pour le move ${pendingCharge.moveId}.',
        );
      }

      return BattleActionFight(
        chargedMove,
        moveIndex: pendingCharge.moveIndex,
      );
    }

    if (volatileState.mustRecharge) {
      return const BattleActionRecharge();
    }

    return null;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Depuis BE4, la résolution d'un move n'est plus "toujours hit" :
  /// - la tentative peut consommer 1 PP puis rater ;
  /// - ce miss n'annule ni l'ordre du tour ni la consommation ;
  /// - seuls les effets réellement supportés sont alors appliqués sur hit.
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    final request = decisionRequest;
    if (request is BattleWaitRequest) {
      throw StateError(
        'Aucune décision joueur n’est attendue actuellement (${request.reason.name}).',
      );
    }
    if (!request.allows(choice)) {
      throw _illegalChoiceStateError(request, choice);
    }
    if (request case BattleForcedReplacementRequest()) {
      if (pendingTurn != null) {
        return _resumePendingTurnWithReplacement(
          session: this,
          choice: choice as PlayerBattleChoiceSwitch,
        );
      }
      return _applyForcedPlayerReplacement(
        session: this,
        choice: choice as PlayerBattleChoiceSwitch,
      );
    }

    final forcedPlayerAction = switch (request) {
      BattleContinueRequest() => _resolveForcedAction(
          combatantLabel: 'player',
          combatant: state.player,
        ),
      _ => null,
    };
    if (request is BattleContinueRequest && forcedPlayerAction == null) {
      throw StateError(
        'La request ${request.kind.name} ne correspond plus à un vrai tour forcé côté moteur.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (request is! BattleContinueRequest && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        opponentPolicy: opponentPolicy,
        pendingTurn: null,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        opponentPolicy: opponentPolicy,
        pendingTurn: null,
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi via le seam adverse borné.
    final enemyAction = _resolveEnemyAction();

    // R2 consolide ici le seam scheduler déjà vivant sans élargir le slice :
    // - `applyChoice` reste responsable de la frontière request -> action ;
    // - la planification locale du tour devient explicite via `_BattleTurnPlan` ;
    // - la consommation de queue et la reprise vivent désormais dans le
    //   scheduler dédié plutôt que d'être entassées dans cette méthode ;
    // - la résolution métier des moves, hazards et conditions reste, elle,
    //   dans `BattleSession`.
    final turnPlan = _planInitialTurn(
      session: this,
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: state.player,
      enemy: state.enemy,
      field: state.field,
    );
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction: turnPlan.reportedPlayerAction,
      originalEnemyAction: turnPlan.reportedEnemyAction,
    );
    _consumeTurnPlan(
      session: this,
      plan: turnPlan,
      turn: turn,
    );
    final turnResult = _buildTurnResultFromContext(
      turn: turn,
      playerAction: turnPlan.reportedPlayerAction,
      enemyAction: turnPlan.reportedEnemyAction,
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = turn.pendingTurn != null
        ? null
        : _determineOutcome(
            turn.playerSide,
            turn.enemySide,
            turn.field,
          );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      // On conserve maintenant la trace du dernier tour même s'il termine le
      // combat :
      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
      //   application de statut terminale redeviendraient invisibles ;
      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
      //   passent pas par `_resolveTurn`.
      currentTurn: turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: turn.rng,
      opponentPolicy: opponentPolicy,
      pendingTurn: turn.pendingTurn,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required BattleSideState side,
    required int reserveIndex,
    required bool wasForced,
  }) {
    final reserve = side.reserve;
    if (reserveIndex < 0 || reserveIndex >= reserve.length) {
      throw RangeError.index(reserveIndex, reserve, 'reserveIndex');
    }

    final incoming = reserve[reserveIndex];
    if (incoming.isFainted) {
      throw StateError(
        'Le switch demandé vise un Pokémon de réserve déjà K.O.',
      );
    }

    // BE10 choisit de conserver une réserve de taille stable :
    // - le membre entrant quitte la réserve ;
    // - l'actif sortant y retourne au même emplacement après reset ;
    // - chaque participant battle reste donc présent exactement une fois,
    //   ce qui simplifie le write-back runtime final.
    final updatedReserve = List<BattleCombatant>.of(reserve);
    updatedReserve[reserveIndex] = side.active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      side: side.withActiveAndReserve(
        active: incoming,
        reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      ),
      event: BattleSwitchEvent.switched(
        side: side.id,
        fromSpeciesId: side.active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        return i;
      }
    }
    return null;
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        final move = state.player.moves[choice.moveIndex];
        if (!move.hasUsablePp) {
          throw StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
        return BattleActionFight(
          move,
          moveIndex: choice.moveIndex,
        );
      }
      throw StateError(
        'Le choix Fight(${choice.moveIndex}) vise un slot move invalide.',
      );
    } else if (choice is PlayerBattleChoiceSwitch) {
      if (choice.reserveIndex < 0 ||
          choice.reserveIndex >= state.playerReserve.length) {
        throw StateError(
          'Le switch demandé vise un index de réserve invalide (${choice.reserveIndex}).',
        );
      }
      if (state.playerReserve[choice.reserveIndex].isFainted) {
        throw StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
      return BattleActionSwitch(
        reserveIndex: choice.reserveIndex,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
    }
    throw StateError(
      'Type de choix joueur non supporté par _choiceToAction: ${choice.runtimeType}.',
    );
  }

  String _describePlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) => 'Fight($moveIndex)',
      PlayerBattleChoiceSwitch(:final reserveIndex) => 'Switch($reserveIndex)',
      PlayerBattleChoiceRun() => 'Run()',
      PlayerBattleChoiceCapture() => 'Capture()',
      PlayerBattleChoiceContinue() => 'Continue()',
    };
  }

  StateError _illegalChoiceStateError(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    // On garde ici quelques diagnostics métier précis pour ne pas perdre en
    // lisibilité par rapport à l'ancien monde "liste plate" :
    // - un move à 0 PP doit rester identifiable comme tel ;
    // - un switch invalide ou vers une réserve K.O. mérite aussi un message
    //   ciblé ;
    // - tout le reste peut retomber sur le message générique request/kind.
    if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
      if (moveIndex >= 0 && moveIndex < state.player.moves.length) {
        final move = state.player.moves[moveIndex];
        if (!move.hasUsablePp) {
          return StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
      }
    }

    if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
      if (reserveIndex < 0 || reserveIndex >= state.playerReserve.length) {
        return StateError(
          'Le switch demandé vise un index de réserve invalide ($reserveIndex).',
        );
      }
      if (state.playerReserve[reserveIndex].isFainted) {
        return StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
    }

    return StateError(
      'Le choix ${_describePlayerChoice(choice)} est illégal pour la request courante ${request.kind.name}.',
    );
  }

  /// Résout l'action adverse sans re-déverser la policy dans la session.
  ///
  /// Répartition volontaire des responsabilités :
  /// - la session garde les cas forcés (`charge`, `recharge`) et les échecs
  ///   explicites (`aucun move`, `plus de PP`, ennemi déjà K.O.) ;
  /// - la policy ne tranche qu'entre des actions fight déjà légales ;
  /// - on évite ainsi à la fois un faux framework d'IA et le retour de la
  ///   logique de difficulté au milieu de `battle_session.dart`.
  BattleAction _resolveEnemyAction() {
    final forcedAction = _resolveForcedAction(
      combatantLabel: 'enemy',
      combatant: state.enemy,
    );
    if (forcedAction != null) {
      return forcedAction;
    }

    // R1 a déjà rendu ce dead-end honnête : un ennemi K.O. ne joue simplement
    // aucune action pendant ce tour.
    if (state.enemy.isFainted) {
      return const BattleActionNone();
    }
    if (state.enemy.moves.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a aucun move configuré et ne peut pas agir honnêtement.',
      );
    }

    final legalFightActions = _availableEnemyFightActions();
    if (legalFightActions.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
      );
    }

    if (setup.isTrainerBattle) {
      final legalSwitchOptions = _availableEnemyVoluntarySwitchOptions();
      final voluntarySwitch = opponentPolicy.chooseVoluntarySwitch(
        activeCombatant: state.enemy,
        legalFightActions: List<BattleActionFight>.unmodifiable(
          legalFightActions,
        ),
        legalSwitchOptions: List<BattleOpponentReplacementOption>.unmodifiable(
          legalSwitchOptions,
        ),
        didEnemySwitchLastTurn: _didEnemySwitchLastTurn(),
      );
      if (voluntarySwitch != null) {
        if (!legalSwitchOptions.contains(voluntarySwitch)) {
          throw StateError(
            'BattleOpponentPolicy doit retourner une des options de switch volontaire légales fournies par la session.',
          );
        }
        return BattleActionSwitch(reserveIndex: voluntarySwitch.reserveIndex);
      }
    }

    // Garde-fou de périmètre lots 3 à 5 :
    // - la policy reçoit uniquement des actions fight déjà légales ;
    // - elle doit en retourner une parmi cette liste, sans en synthétiser une
    //   nouvelle ni rouvrir switch volontaire/targeting ;
    // - si une future policy enfreint ce contrat, on préfère échouer ici
    //   explicitement plutôt que laisser entrer une action mensongère.
    final selectedAction = opponentPolicy.chooseFightAction(
      legalFightActions: List<BattleActionFight>.unmodifiable(
        legalFightActions,
      ),
    );
    if (!legalFightActions.contains(selectedAction)) {
      throw StateError(
        'BattleOpponentPolicy doit retourner une des actions fight légales fournies par la session.',
      );
    }
    return selectedAction;
  }

  List<BattleOpponentReplacementOption> _availableEnemyVoluntarySwitchOptions() {
    if (state.enemy.isFainted) {
      return const <BattleOpponentReplacementOption>[];
    }

    final options = <BattleOpponentReplacementOption>[];
    for (final reserveIndex in _selectableReserveIndices(state.enemyReserve)) {
      options.add(
        BattleOpponentReplacementOption(
          reserveIndex: reserveIndex,
          combatant: state.enemyReserve[reserveIndex],
        ),
      );
    }
    return List<BattleOpponentReplacementOption>.unmodifiable(options);
  }

  bool _didEnemySwitchLastTurn() {
    final previousTurn = state.currentTurn;
    if (previousTurn == null) {
      return false;
    }
    for (final event in previousTurn.switchEvents) {
      if (event.side == BattleSideId.enemy &&
          event.kind == BattleSwitchEventKind.switched) {
        return true;
      }
    }
    return false;
  }

  /// Calcule la liste des actions fight adverse actuellement légales.
  ///
  /// Ce helper reste côté session pour une raison précise :
  /// - la légalité des moves dépend encore de l'état battle courant et des PP
  ///   réellement portés par le moteur ;
  /// - déplacer cette logique dans la policy la rendrait responsable de
  ///   valider l'état battle, ce qui dériverait déjà vers un seam trop riche ;
  /// - la policy n'a donc plus qu'à choisir, pas à déterminer ce qui est légal.
  List<BattleActionFight> _availableEnemyFightActions() {
    final actions = <BattleActionFight>[];
    for (var i = 0; i < state.enemy.moves.length; i++) {
      final move = state.enemy.moves[i];
      if (move.hasUsablePp) {
        actions.add(
          BattleActionFight(
            move,
            moveIndex: i,
          ),
        );
      }
    }
    return List<BattleActionFight>.unmodifiable(actions);
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit ;
  /// - BE7 ajoute ensuite un petit sous-ensemble `applyStatus` et un blocage
  ///   d'action par paralysie, sans ouvrir un système de statuts complet.
  ///
  /// Cette application immédiate reste importante :
  /// - un `growl` du joueur peut déjà réduire une contre-attaque physique
  ///   ennemie plus tard dans le même tour s'il touche ;
  /// - mais un changement de `speed` ne réordonne jamais rétroactivement un
  ///   tour déjà ordonné au début de `_resolveTurn`.
  _ResolvedMoveExecution _resolveMoveExecution({
    required BattleSlotRef attackerSlot,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleSlotRef targetSlot,
    required BattleRng rng,
  }) {
    final actionAttempt = _conditionEngine.runActionAttempt(
      attackerSlot: attackerSlot,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
      rng: rng,
    );

    if (actionAttempt.outcome == BattleActionAttemptOutcome.preventedAction) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: actionAttempt.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromStatus(actionAttempt.statusEvents),
      );
    }

    if (actionAttempt.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: actionAttempt.volatileEvents,
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromVolatile(actionAttempt.volatileEvents),
      );
    }

    final preHitVolatileEvents =
        List<BattleVolatileEvent>.of(actionAttempt.volatileEvents);
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionAttempt.rng,
    );

    if (!hitCheck.didHit) {
      final missExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: actionAttempt.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: false,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: missExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: missExecution,
        ),
      );
    }

    final hitInterception = _conditionEngine.runHitInterception(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: actionAttempt.attacker,
      defender: defender,
    );
    preHitVolatileEvents.addAll(hitInterception.volatileEvents);

    if (hitInterception.blockedByProtect) {
      final blockedExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: hitInterception.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: true,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: hitInterception.attacker,
        defender: hitInterception.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: blockedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: blockedExecution,
        ),
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: hitInterception.attacker,
      defender: hitInterception.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    final updatedAttacker = damageResult.wasImmune
        ? hitInterception.attacker
        : hitInterception.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? hitInterception.defender
        : hitInterception.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final postMoveConditions = _conditionEngine.runMoveResolved(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: updatedAttacker,
      defender: defenderAfterHit,
      field: field,
      wasImmune: damageResult.wasImmune,
      rng: damageResult.nextRng,
    );
    final preExecutionVolatileEvents =
        List<BattleVolatileEvent>.unmodifiable(preHitVolatileEvents);
    final allVolatileEvents = <BattleVolatileEvent>[
      ...preHitVolatileEvents,
      ...postMoveConditions.volatileEvents,
    ];

    final resolvedExecution = BattleMoveExecution(
      attackerSlot: attackerSlot,
      move: postMoveConditions.attacker.moves[moveIndex],
      targetKind: _resolveExecutionTargetKind(move),
      targetSlot: _resolveExecutionTargetSlot(
        move: move,
        attackerSlot: attackerSlot,
        opponentSlot: targetSlot,
      ),
      targetSideRef: _resolveExecutionTargetSide(
        move: move,
        opponentSlot: targetSlot,
      ),
      damage: damageResult.damage,
      didHit: true,
      didCrit: damageResult.didCrit,
      criticalMultiplier: damageResult.criticalMultiplier,
      stabMultiplier: damageResult.stabMultiplier,
      typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
    );

    return _ResolvedMoveExecution(
      attacker: postMoveConditions.attacker,
      defender: postMoveConditions.defender,
      field: postMoveConditions.field,
      rng: postMoveConditions.rng,
      execution: resolvedExecution,
      statusEvents: postMoveConditions.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(allVolatileEvents),
      fieldEvents: postMoveConditions.fieldEvents,
      timeline: _buildMoveTimeline(
        preExecutionVolatileEvents: preExecutionVolatileEvents,
        execution: resolvedExecution,
        statusEvents: postMoveConditions.statusEvents,
        fieldEvents: postMoveConditions.fieldEvents,
        postExecutionVolatileEvents: postMoveConditions.volatileEvents,
      ),
    );
  }

  _ResolvedHitCheck _resolveHitCheck({
    required BattleMove move,
    required BattleRng rng,
  }) {
    if (move.accuracy.isAlwaysHits || move.accuracy.value >= 100) {
      // Recadrage volontaire de BE4 :
      // - `alwaysHits` doit évidemment bypasser le hit check ;
      // - dans le moteur actuel, `percent(100)` est également déterministe,
      //   car nous n'avons encore ni accuracy stages, ni evasion, ni autres
      //   modificateurs de précision ;
      // - consommer du RNG sur 100% n'apporterait donc aucune vérité
      //   supplémentaire et compliquerait artificiellement les tests.
      return _ResolvedHitCheck(
        didHit: true,
        nextRng: rng,
      );
    }

    final roll = rng.nextPercentRoll();
    return _ResolvedHitCheck(
      didHit: roll.value <= move.accuracy.value,
      nextRng: roll.next,
    );
  }

  /// Résout la famille de cible observable d'une exécution.
  ///
  /// Phase G garde cette aide volontairement locale à la session :
  /// - elle évite de re-disperser la logique "combatant vs field" ;
  /// - elle ne transforme pas `BattleMoveTarget` en système de targeting riche ;
  /// - elle sert uniquement à produire un contrat d'exécution plus honnête.
  BattleMoveExecutionTargetKind _resolveExecutionTargetKind(
    BattleMove move,
  ) {
    return switch (move.target) {
      BattleMoveTarget.field => BattleMoveExecutionTargetKind.field,
      BattleMoveTarget.opponentSide => BattleMoveExecutionTargetKind.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        BattleMoveExecutionTargetKind.combatant,
    };
  }

  /// Résout le slot cible observable quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - en singles, `self` et `opponent` suffisent encore ;
  /// - `field` garde explicitement l'absence de slot ;
  /// - on n'anticipe ni doubles, ni targeting multiple, ni side targeting.
  BattleSlotRef? _resolveExecutionTargetSlot({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerSlot,
      BattleMoveTarget.field || BattleMoveTarget.opponentSide => null,
      BattleMoveTarget.opponent || BattleMoveTarget.unspecified => opponentSlot,
    };
  }

  BattleSideId? _resolveExecutionTargetSide({
    required BattleMove move,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.opponentSide => opponentSlot.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.field ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        null,
    };
  }

  /// Calcule les dégâts standards du moteur battle MVP enrichi.
  ///
  /// BE2 ne bascule toujours pas vers une formule Pokémon complète. Le but est
  /// maintenant plus honnête que l'ancien simple `damage = power` :
  /// - les dégâts standards reposent enfin sur un vrai snapshot de stats ;
  /// - les moves physiques utilisent `attack` vs `defense` ;
  /// - les moves spéciaux utilisent `specialAttack` vs `specialDefense` ;
  /// - les stages continuent à s'appliquer, mais sur ces vraies bases ;
  /// - `speed` influence désormais l'ordre d'action dans BE3, mais reste sans
  ///   rôle direct dans les dégâts.
  ///
  /// Frontière explicitement conservée :
  /// - pas d'accuracy/evasion stages ;
  /// - pas de règles Pokémon avancées de critique ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule ;
  /// - BE6 ajoute seulement :
  ///   - une vraie chance de critique minimale ;
  ///   - un multiplicateur critique fixe ;
  ///   - aucune interaction avancée avec stages / items / abilities.
  _ResolvedDamage _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleRng rng,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
        nextRng: rng,
      );
    }

    final offensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.attack,
      BattleMoveCategory.special => BattleStatId.specialAttack,
      BattleMoveCategory.status => BattleStatId.attack,
    };
    final defensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.defense,
      BattleMoveCategory.special => BattleStatId.specialDefense,
      BattleMoveCategory.status => BattleStatId.defense,
    };

    // Ordre de calcul volontairement documenté :
    // 1. on part du snapshot de stats résolu par le runtime ;
    // 2. on applique les stages côté attaquant et défenseur ;
    // 3. on utilise ensuite une formule entière simple, Pokémon-like ;
    // 4. on garde enfin un minimum de 1 dégât pour tout move non-status
    //    ayant passé le bridge BE1.
    final effectiveAttack = _resolveEffectiveStat(
      baseStat: _statValueFor(attacker.stats, offensiveStatId),
      multiplier: attacker.statStages.multiplierFor(offensiveStatId),
    );
    final effectiveDefense = _resolveEffectiveStat(
      baseStat: _statValueFor(defender.stats, defensiveStatId),
      multiplier: defender.statStages.multiplierFor(defensiveStatId),
    );
    final safePower = move.power < 0 ? 0 : move.power;
    final levelFactor = ((2 * attacker.level) ~/ 5) + 2;
    final baseDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();

    // BE5 ajoute ici la plus petite consommation honnête du type :
    // - STAB simple à 1.5 ;
    // - type chart standard ;
    // - immunité à 0 ;
    // - double type multiplicatif ;
    // - toujours aucune abilities, aucun item, aucune Tera ;
    // - BE9 n'ajoute ensuite qu'un unique modificateur météo local :
    //   la pluie pour Eau/Feu.
    final stabMultiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: move.type,
      attackerTyping: attacker.typing,
    );
    final typeEffectivenessMultiplier =
        BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: move.type,
      defenderTyping: defender.typing,
    );

    if (typeEffectivenessMultiplier == 0.0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
        nextRng: rng,
      );
    }

    // BE6 garde ici un ordre de résolution petit mais honnête :
    // 1. le hit check a déjà eu lieu en amont ;
    // 2. on vérifie ensuite l'immunité via le type chart ;
    // 3. seulement pour un hit offensif non immunisé, on résout un crit ;
    // 4. puis on applique STAB / efficacité de type et le clamp final.
    //
    // Ce choix évite de "dépenser" un tirage de crit sur un move qui n'aurait
    // de toute façon aucun effet. Pour le sous-ensemble actuel, c'est plus
    // honnête et reste mathématiquement neutre sur le résultat observable.
    final criticalHit = _resolveCriticalHit(
      move: move,
      rng: rng,
    );

    // Ordre de multiplication BE6 :
    // 1. baseDamage déterministe BE2 ;
    // 2. critique minimal BE6 ;
    // 3. malus de brûlure sur les moves physiques dans BE7 ;
    // 4. STAB ;
    // 5. effectiveness / résistance ;
    // 6. météo BE9 réellement supportée ;
    // 7. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final burnMultiplier = _conditionEngine.resolveStatusDamageMultiplier(
      move: move,
      attacker: attacker,
    );
    final weatherMultiplier = _conditionEngine.resolveFieldDamageMultiplier(
      move: move,
      field: field,
    );
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            burnMultiplier *
            stabMultiplier *
            typeEffectivenessMultiplier *
            weatherMultiplier)
        .floor();
    final finalDamage = scaledDamage < 1 ? 1 : scaledDamage;

    return _ResolvedDamage(
      damage: finalDamage,
      didCrit: criticalHit.didCrit,
      criticalMultiplier: criticalHit.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      nextRng: criticalHit.nextRng,
    );
  }

  _ResolvedCriticalHit _resolveCriticalHit({
    required BattleMove move,
    required BattleRng rng,
  }) {
    final chance = _critChanceForRatio(move.critRatio);
    if (chance.didOccurWithoutRng) {
      return _ResolvedCriticalHit(
        didCrit: true,
        multiplier: _criticalHitMultiplier,
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return _ResolvedCriticalHit(
      didCrit: roll.didOccur,
      multiplier: roll.didOccur ? _criticalHitMultiplier : 1.0,
      nextRng: roll.next,
    );
  }

  _CritChance _critChanceForRatio(int critRatio) {
    // Table BE6 volontairement explicite :
    // - on suit une lecture moderne Pokémon-like des stages de crit ;
    // - `1` reste le ratio neutre du canonique projet ;
    // - on ne prétend pas ouvrir Focus Energy, Lucky Chant ou d'autres
    //   modificateurs indirects.
    //
    // Mini-fix BE6 puis BE6-mini-fix-2 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide" ;
    // - le contrat public est désormais mieux verrouillé en amont, donc cette
    //   garde sert surtout de défense en profondeur pour un état incohérent
    //   qui réapparaîtrait à l'intérieur même de `map_battle` ;
    // - on préfère maintenant un `StateError` explicite, parce qu'à ce stade
    //   il s'agit d'un état battle incohérent, pas d'une simple option métier.
    if (critRatio < 1) {
      throw StateError(
        'Battle critical ratio must be >= 1; got $critRatio.',
      );
    }
    return switch (critRatio) {
      1 => const _CritChance(numerator: 1, denominator: 24),
      2 => const _CritChance(numerator: 1, denominator: 8),
      3 => const _CritChance(numerator: 1, denominator: 2),
      _ => const _CritChance.always(),
    };
  }

  int _statValueFor(BattleStatsSnapshot snapshot, BattleStatId stat) {
    return switch (stat) {
      BattleStatId.attack => snapshot.attack,
      BattleStatId.defense => snapshot.defense,
      BattleStatId.specialAttack => snapshot.specialAttack,
      BattleStatId.specialDefense => snapshot.specialDefense,
      BattleStatId.speed => snapshot.speed,
    };
  }

  int _resolveEffectiveSpeed(BattleCombatant combatant) {
    // L'ordre BE3 repose sur une vitesse effective déterministe :
    // - snapshot de speed résolu par le runtime ;
    // - multiplicateur de stages battle déjà présent ;
    // - Phase E délègue ensuite à l'engine conditionnel le malus simple de
    //   paralysie, pour arrêter de disperser cette règle métier ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    return _conditionEngine.resolveStatusAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
    );
  }

  int _resolveEffectiveStat({
    required int baseStat,
    required double multiplier,
  }) {
    // BE2 garde ici une règle simple et déterministe :
    // - pas de fraction stockée ;
    // - pas de rounding ambigu ;
    // - on applique les stages par multiplication, puis `floor` ;
    // - on clamp enfin au minimum 1 pour ne jamais diviser par 0 ni produire
    //   une stat offensive/défensive absurde.
    final resolved = (baseStat * multiplier).floor();
    return resolved < 1 ? 1 : resolved;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Politique BE10, volontairement petite et explicite :
  /// - les remplacements automatiques honnêtes ont déjà été tentés avant
  ///   d'entrer ici ;
  /// - si l'ennemi actif est encore K.O. à ce stade, il n'a plus de réserve
  ///   valide et le joueur gagne ;
  /// - sinon, si le joueur actif est encore K.O. mais qu'une réserve valide
  ///   existe encore, le combat continue pour laisser place au switch forcé ;
  /// - sinon, si le joueur actif est encore K.O., il n'a plus de réserve
  ///   valide et le joueur perd ;
  /// - sinon le combat continue ;
  /// - en cas de double K.O. sans réserve des deux côtés, on conserve donc la
  ///   politique historique "enemy d'abord", ce qui produit une victoire.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleSideState playerSide,
    BattleSideState enemySide,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemySide.active.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (playerSide.active.isFainted) {
      if (_firstUsableReserveIndex(playerSide.reserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }

  List<BattleTurnEvent> _buildMoveTimeline({
    List<BattleVolatileEvent> preExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
    BattleMoveExecution? execution,
    List<BattleStatusEvent> statusEvents = const <BattleStatusEvent>[],
    List<BattleFieldEvent> fieldEvents = const <BattleFieldEvent>[],
    List<BattleVolatileEvent> postExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
  }) {
    // BE10A garde une granularité volontairement petite :
    // - on ne reconstruit plus l'ordre en UI ;
    // - on fabrique ici une chronologie ordonnée au moment où le moteur
    //   connaît réellement l'enchaînement causal ;
    // - on ne descend toutefois pas dans une micro-chronologie Showdown-like
    //   de chaque sous-étape interne.
    final timeline = <BattleTurnEvent>[
      ..._turnEventsFromVolatile(preExecutionVolatileEvents),
      if (execution != null) BattleTurnExecutionEvent(execution),
      ..._turnEventsFromStatus(statusEvents),
      ..._turnEventsFromField(fieldEvents),
      ..._turnEventsFromVolatile(postExecutionVolatileEvents),
    ];
    return List<BattleTurnEvent>.unmodifiable(timeline);
  }

  List<BattleTurnEvent> _turnEventsFromStatus(
    Iterable<BattleStatusEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStatusEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromVolatile(
    Iterable<BattleVolatileEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnVolatileEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromField(
    Iterable<BattleFieldEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnFieldEvent.new),
    );
  }
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.execution,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.timeline,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedDamage {
  const _ResolvedDamage({
    required this.damage,
    required this.didCrit,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
    required this.nextRng,
  });

  final int damage;
  final bool didCrit;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;
  final BattleRng nextRng;

  bool get wasImmune => typeEffectivenessMultiplier == 0.0;
}

class _ResolvedCriticalHit {
  const _ResolvedCriticalHit({
    required this.didCrit,
    required this.multiplier,
    required this.nextRng,
  });

  final bool didCrit;
  final double multiplier;
  final BattleRng nextRng;
}

class _CritChance {
  const _CritChance({
    required this.numerator,
    required this.denominator,
  }) : didOccurWithoutRng = false;

  const _CritChance.always()
      : numerator = 1,
        denominator = 1,
        didOccurWithoutRng = true;

  final int numerator;
  final int denominator;
  final bool didOccurWithoutRng;
}

```
### /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_opponent_policy_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    moves: moves,
  );
}

final class _LastLegalFightPolicy implements BattleOpponentPolicy {
  List<BattleActionFight>? lastLegalFightActions;
  List<BattleOpponentReplacementOption>? lastLegalReplacementOptions;
  List<BattleOpponentReplacementOption>? lastLegalVoluntarySwitchOptions;
  BattleCombatant? lastActiveCombatant;
  bool? lastDidEnemySwitchLastTurn;

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    lastLegalFightActions = legalFightActions;
    return legalFightActions.last;
  }

  @override
  BattleOpponentReplacementOption chooseReplacement({
    required List<BattleOpponentReplacementOption> legalReplacementOptions,
  }) {
    lastLegalReplacementOptions = legalReplacementOptions;
    return legalReplacementOptions.last;
  }

  @override
  BattleOpponentReplacementOption? chooseVoluntarySwitch({
    required BattleCombatant activeCombatant,
    required List<BattleActionFight> legalFightActions,
    required List<BattleOpponentReplacementOption> legalSwitchOptions,
    required bool didEnemySwitchLastTurn,
  }) {
    lastActiveCombatant = activeCombatant;
    lastLegalFightActions = legalFightActions;
    lastLegalVoluntarySwitchOptions = legalSwitchOptions;
    lastDidEnemySwitchLastTurn = didEnemySwitchLastTurn;
    return legalSwitchOptions.isEmpty ? null : legalSwitchOptions.last;
  }
}

void main() {
  group('BattleOpponentPolicy seam', () {
    test(
        'battleOpponentPolicyForDifficulty maps product difficulty 1..10 to a small set of internal policies',
        () {
      expect(
        battleOpponentPolicyForDifficulty(null),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(0),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(3),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(4),
        isA<BattleHighestPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(7),
        isA<BattleHighestPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(8),
        isA<BattleHighestExpectedPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(42),
        isA<BattleHighestExpectedPowerOpponentPolicy>(),
      );
    });

    test('BattleFirstLegalOpponentPolicy picks the first legal fight action',
        () {
      const firstMove = BattleMove(
        id: 'first',
        name: 'First',
        power: 10,
      );
      const secondMove = BattleMove(
        id: 'second',
        name: 'Second',
        power: 20,
      );
      const firstAction = BattleActionFight(
        firstMove,
        moveIndex: 0,
      );
      const secondAction = BattleActionFight(
        secondMove,
        moveIndex: 1,
      );
      const policy = BattleFirstLegalOpponentPolicy();

      final chosenAction = policy.chooseFightAction(
        legalFightActions: const <BattleActionFight>[
          firstAction,
          secondAction,
        ],
      );

      expect(chosenAction.move.id, equals('first'));
      expect(chosenAction.moveIndex, equals(0));
    });

    test(
        'higher internal policies stay fight-only but choose stronger or more reliable damaging moves',
        () {
      const setupMove = BattleMove(
        id: 'growl',
        name: 'Growl',
        power: 0,
        category: BattleMoveCategory.status,
        target: BattleMoveTarget.opponent,
        accuracy: BattleMoveAccuracy.alwaysHits(),
      );
      const heavyButRiskyMove = BattleMove(
        id: 'mega_punch',
        name: 'Mega Punch',
        power: 100,
        accuracy: BattleMoveAccuracy.percent(value: 50),
      );
      const reliableMove = BattleMove(
        id: 'swift_strike',
        name: 'Swift Strike',
        power: 60,
        accuracy: BattleMoveAccuracy.percent(value: 100),
      );
      const legalFightActions = <BattleActionFight>[
        BattleActionFight(setupMove, moveIndex: 0),
        BattleActionFight(heavyButRiskyMove, moveIndex: 1),
        BattleActionFight(reliableMove, moveIndex: 2),
      ];

      final lowDifficultyChoice = battleOpponentPolicyForDifficulty(2)
          .chooseFightAction(legalFightActions: legalFightActions);
      final midDifficultyChoice = battleOpponentPolicyForDifficulty(5)
          .chooseFightAction(legalFightActions: legalFightActions);
      final highDifficultyChoice = battleOpponentPolicyForDifficulty(9)
          .chooseFightAction(legalFightActions: legalFightActions);

      expect(lowDifficultyChoice.moveIndex, equals(0));
      expect(midDifficultyChoice.moveIndex, equals(1));
      expect(highDifficultyChoice.moveIndex, equals(2));
    });

    test(
        'BattleSession delegates enemy move selection to the injected opponent policy using only legal fight actions',
        () {
      final policy = _LastLegalFightPolicy();
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: _combatant(
            speciesId: 'player',
            lineupIndex: 0,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'wait',
                name: 'Wait',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          enemyPokemon: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'empty',
                name: 'Empty',
                power: 5,
                pp: 10,
                currentPp: 0,
              ),
              BattleMoveData(
                id: 'weak',
                name: 'Weak',
                power: 5,
                pp: 10,
                currentPp: 10,
              ),
              BattleMoveData(
                id: 'strong',
                name: 'Strong',
                power: 20,
                pp: 10,
                currentPp: 10,
              ),
            ],
          ),
          isTrainerBattle: true,
          trainerId: 'trainer',
        ),
        opponentPolicy: policy,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      final resolved = session.applyChoice(const PlayerBattleChoiceFight(0));
      final enemyAction = resolved.state.currentTurn!.enemyAction;

      expect(enemyAction, isA<BattleActionFight>());
      expect((enemyAction as BattleActionFight).move.id, equals('strong'));
      expect(enemyAction.moveIndex, equals(2));
      expect(policy.lastLegalFightActions, isNotNull);
      expect(
        policy.lastLegalFightActions!
            .map((action) => action.moveIndex)
            .toList(growable: false),
        orderedEquals(<int>[1, 2]),
      );
    });

    test(
        'basic replacement policies keep the historical first usable reserve fallback',
        () {
      final lowDifficultyChoice = battleOpponentPolicyForDifficulty(2)
          .chooseReplacement(
        legalReplacementOptions: _replacementOptions(),
      );
      final legacyChoice = battleOpponentPolicyForDifficulty(null)
          .chooseReplacement(
        legalReplacementOptions: _replacementOptions(),
      );

      expect(lowDifficultyChoice.reserveIndex, equals(0));
      expect(lowDifficultyChoice.combatant.speciesId, equals('status_wall'));
      expect(legacyChoice.reserveIndex, equals(0));
      expect(legacyChoice.combatant.speciesId, equals('status_wall'));
    });

    test(
        'aggressive replacement policies prefer the reserve with the strongest damaging move',
        () {
      final choice = battleOpponentPolicyForDifficulty(5).chooseReplacement(
        legalReplacementOptions: _replacementOptions(),
      );

      expect(choice.reserveIndex, equals(1));
      expect(choice.combatant.speciesId, equals('slow_nuke'));
    });

    test(
        'calculated replacement policies prefer a faster healthier attacker over the raw nuke',
        () {
      final choice = battleOpponentPolicyForDifficulty(9).chooseReplacement(
        legalReplacementOptions: _replacementOptions(),
      );

      expect(choice.reserveIndex, equals(2));
      expect(choice.combatant.speciesId, equals('fast_striker'));
    });

    test(
        'replacement policies fall back to the first usable reserve when no candidate has a meaningful offensive edge',
        () {
      final choice = battleOpponentPolicyForDifficulty(9).chooseReplacement(
        legalReplacementOptions: <BattleOpponentReplacementOption>[
          BattleOpponentReplacementOption(
            reserveIndex: 0,
            combatant: _battleCombatant(
              speciesId: 'wall_a',
              lineupIndex: 1,
              moves: const <BattleMoveData>[
                BattleMoveData(
                  id: 'growl',
                  name: 'Growl',
                  power: 0,
                  category: BattleMoveCategory.status,
                  target: BattleMoveTarget.opponent,
                ),
              ],
            ),
          ),
          BattleOpponentReplacementOption(
            reserveIndex: 1,
            combatant: _battleCombatant(
              speciesId: 'wall_b',
              lineupIndex: 2,
              moves: const <BattleMoveData>[
                BattleMoveData(
                  id: 'tail_whip',
                  name: 'Tail Whip',
                  power: 0,
                  category: BattleMoveCategory.status,
                  target: BattleMoveTarget.opponent,
                ),
              ],
            ),
          ),
        ],
      );

      expect(choice.reserveIndex, equals(0));
      expect(choice.combatant.speciesId, equals('wall_a'));
    });

    test(
        'replacement policies ignore damaging moves that no longer have usable PP',
        () {
      final legalReplacementOptions = <BattleOpponentReplacementOption>[
        BattleOpponentReplacementOption(
          reserveIndex: 0,
          combatant: _battleCombatant(
            speciesId: 'spent_nuke',
            lineupIndex: 1,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 200,
                category: BattleMoveCategory.special,
                target: BattleMoveTarget.opponent,
                pp: 5,
                currentPp: 0,
              ),
            ],
          ),
        ),
        BattleOpponentReplacementOption(
          reserveIndex: 1,
          combatant: _battleCombatant(
            speciesId: 'usable_striker',
            lineupIndex: 2,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 75,
                category: BattleMoveCategory.physical,
                target: BattleMoveTarget.opponent,
              ),
            ],
          ),
        ),
      ];

      final aggressiveChoice = battleOpponentPolicyForDifficulty(5)
          .chooseReplacement(
        legalReplacementOptions: legalReplacementOptions,
      );
      final calculatedChoice = battleOpponentPolicyForDifficulty(9)
          .chooseReplacement(
        legalReplacementOptions: legalReplacementOptions,
      );

      expect(aggressiveChoice.reserveIndex, equals(1));
      expect(aggressiveChoice.combatant.speciesId, equals('usable_striker'));
      expect(calculatedChoice.reserveIndex, equals(1));
      expect(calculatedChoice.combatant.speciesId, equals('usable_striker'));
    });

    test(
        'basic voluntary switch behavior keeps the legacy fallback and never switches voluntarily',
        () {
      final choice = battleOpponentPolicyForDifficulty(null).chooseVoluntarySwitch(
        activeCombatant: _battleCombatant(
          speciesId: 'status_wall',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        legalFightActions: const <BattleActionFight>[
          BattleActionFight(
            BattleMove(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
            moveIndex: 0,
          ),
        ],
        legalSwitchOptions: _replacementOptions(),
        didEnemySwitchLastTurn: false,
      );

      expect(choice, isNull);
    });

    test(
        'aggressive voluntary switch behavior triggers only when the active has no real offensive pressure and a reserve is clearly stronger',
        () {
      final choice = battleOpponentPolicyForDifficulty(5).chooseVoluntarySwitch(
        activeCombatant: _battleCombatant(
          speciesId: 'status_wall',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        legalFightActions: const <BattleActionFight>[
          BattleActionFight(
            BattleMove(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
            moveIndex: 0,
          ),
        ],
        legalSwitchOptions: _replacementOptions(),
        didEnemySwitchLastTurn: false,
      );

      expect(choice, isNotNull);
      expect(choice!.reserveIndex, equals(1));
      expect(choice.combatant.speciesId, equals('slow_nuke'));
    });

    test(
        'calculated voluntary switch behavior can bail out a low HP active when a healthier faster reserve is clearly better',
        () {
      final choice = battleOpponentPolicyForDifficulty(9).chooseVoluntarySwitch(
        activeCombatant: _battleCombatant(
          speciesId: 'doomed_attacker',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 8,
          stats: _stats(attack: 100, specialAttack: 100, speed: 60),
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'slash',
              name: 'Slash',
              power: 70,
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              accuracy: BattleMoveAccuracy.alwaysHits(),
            ),
          ],
        ),
        legalFightActions: const <BattleActionFight>[
          BattleActionFight(
            BattleMove(
              id: 'slash',
              name: 'Slash',
              power: 70,
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              accuracy: BattleMoveAccuracy.alwaysHits(),
            ),
            moveIndex: 0,
          ),
        ],
        legalSwitchOptions: _replacementOptions(),
        didEnemySwitchLastTurn: false,
      );

      expect(choice, isNotNull);
      expect(choice!.reserveIndex, equals(2));
      expect(choice.combatant.speciesId, equals('fast_striker'));
    });

    test(
        'voluntary switch behavior refuses to re-switch immediately after a previous enemy voluntary switch',
        () {
      final choice = battleOpponentPolicyForDifficulty(9).chooseVoluntarySwitch(
        activeCombatant: _battleCombatant(
          speciesId: 'status_wall',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        legalFightActions: const <BattleActionFight>[
          BattleActionFight(
            BattleMove(
              id: 'growl',
              name: 'Growl',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponent,
            ),
            moveIndex: 0,
          ),
        ],
        legalSwitchOptions: _replacementOptions(),
        didEnemySwitchLastTurn: true,
      );

      expect(choice, isNull);
    });

    test(
        'voluntary switch behavior stays put when reserves do not offer a clear or usable gain',
        () {
      final legalSwitchOptions = <BattleOpponentReplacementOption>[
        BattleOpponentReplacementOption(
          reserveIndex: 0,
          combatant: _battleCombatant(
            speciesId: 'spent_nuke',
            lineupIndex: 1,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 200,
                category: BattleMoveCategory.special,
                target: BattleMoveTarget.opponent,
                pp: 5,
                currentPp: 0,
              ),
            ],
          ),
        ),
        BattleOpponentReplacementOption(
          reserveIndex: 1,
          combatant: _battleCombatant(
            speciesId: 'status_wall_b',
            lineupIndex: 2,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'tail_whip',
                name: 'Tail Whip',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
              ),
            ],
          ),
        ),
      ];

      final choice = battleOpponentPolicyForDifficulty(9).chooseVoluntarySwitch(
        activeCombatant: _battleCombatant(
          speciesId: 'usable_attacker',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'slash',
              name: 'Slash',
              power: 75,
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
            ),
          ],
        ),
        legalFightActions: const <BattleActionFight>[
          BattleActionFight(
            BattleMove(
              id: 'slash',
              name: 'Slash',
              power: 75,
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
            ),
            moveIndex: 0,
          ),
        ],
        legalSwitchOptions: legalSwitchOptions,
        didEnemySwitchLastTurn: false,
      );

      expect(choice, isNull);
    });
  });
}

List<BattleOpponentReplacementOption> _replacementOptions() {
  return <BattleOpponentReplacementOption>[
    BattleOpponentReplacementOption(
      reserveIndex: 0,
      combatant: _battleCombatant(
        speciesId: 'status_wall',
        lineupIndex: 1,
        stats: _stats(speed: 20),
        moves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ),
    ),
    BattleOpponentReplacementOption(
      reserveIndex: 1,
      combatant: _battleCombatant(
        speciesId: 'slow_nuke',
        lineupIndex: 2,
        maxHp: 40,
        currentHp: 14,
        stats: _stats(attack: 110, specialAttack: 110, speed: 25),
        moves: const <BattleMoveData>[
          BattleMoveData(
            id: 'hyper_beam',
            name: 'Hyper Beam',
            power: 120,
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ),
    ),
    BattleOpponentReplacementOption(
      reserveIndex: 2,
      combatant: _battleCombatant(
        speciesId: 'fast_striker',
        lineupIndex: 3,
        maxHp: 40,
        currentHp: 36,
        stats: _stats(attack: 95, specialAttack: 95, speed: 95),
        moves: const <BattleMoveData>[
          BattleMoveData(
            id: 'slash',
            name: 'Slash',
            power: 85,
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
            accuracy: BattleMoveAccuracy.alwaysHits(),
          ),
        ],
      ),
    ),
  ];
}

BattleCombatant _battleCombatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    currentHp: currentHp ?? maxHp,
    maxHp: maxHp,
    stats: stats ?? _stats(),
    moves: moves
        .map(
          (move) => BattleMove(
            id: move.id,
            name: move.name,
            power: move.power,
            type: move.type,
            category: move.category,
            target: move.target,
            accuracy: move.accuracy,
            pp: move.pp,
            currentPp: move.currentPp,
          ),
        )
        .toList(growable: false),
  );
}

```
### /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_switch_test.dart

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleMoveData _waitingMove() {
  return const BattleMoveData(
    id: 'wait',
    name: 'Wait',
    power: 0,
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.self,
    accuracy: BattleMoveAccuracy.alwaysHits(),
  );
}

BattleMoveData _tackle({
  int power = 40,
}) {
  return BattleMoveData(
    id: 'tackle',
    name: 'Tackle',
    power: power,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
  bool allowCapture = false,
  BattleFieldState fieldState = const BattleFieldState(),
  BattleRng rng = const BattleSeededRng(),
  BattleOpponentPolicy opponentPolicy = const BattleFirstLegalOpponentPolicy(),
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
      fieldState: fieldState,
    ),
    opponentPolicy: opponentPolicy,
    rng: rng,
  );
}

void main() {
  group('BattleSession BE10 switches and reserves', () {
    test('trainer enemy auto-replaces instead of ending the battle on first KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 40)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
          afterTurn.state.enemyReserve.single.speciesId, equals('lead_enemy'));
      final switchEvent = afterTurn.state.currentTurn!.switchEvents.single;
      expect(switchEvent.side, equals(BattleSideId.enemy));
      expect(
        switchEvent.slot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(switchEvent.actor, equals('enemy'));
      expect(switchEvent.kind, equals(BattleSwitchEventKind.switched));
      expect(switchEvent.wasForced, isTrue);
      expect(
        afterTurn.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>(),
        hasLength(1),
      );
    });

    test(
        'trainer battles without explicit difficulty keep the historical first-usable enemy replacement fallback',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(null),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 40)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            stats: _stats(speed: 25),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            stats: _stats(speed: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('status_wall'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'mid difficulty trainer auto-replaces with the stronger offensive reserve after KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 40)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('slow_nuke'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'high difficulty trainer auto-replaces with the healthier faster attacker after KO',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(9),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 40)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('fast_striker'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'wild battles keep the historical first-usable enemy replacement fallback',
        () {
      final session = _session(
        isTrainerBattle: false,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 20)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'status_wall',
            lineupIndex: 1,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('status_wall'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'enemy auto-replacement ignores fainted reserves before consulting the trainer policy',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_tackle(power: 20)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'fainted_wall',
            lineupIndex: 1,
            currentHp: 0,
            stats: _stats(speed: 20),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          _combatant(
            speciesId: 'slow_nuke',
            lineupIndex: 2,
            currentHp: 14,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
          _combatant(
            speciesId: 'fast_striker',
            lineupIndex: 3,
            currentHp: 36,
            stats: _stats(speed: 95, attack: 95, specialAttack: 95),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('slow_nuke'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'enemy auto-replacement ignores offensive reserves whose big move is out of PP',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _tackle(power: 200),
          ],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'spent_nuke',
            lineupIndex: 1,
            stats: _stats(speed: 25, attack: 110, specialAttack: 110),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 160,
                category: BattleMoveCategory.special,
                target: BattleMoveTarget.opponent,
                pp: 5,
                currentPp: 0,
              ),
            ],
          ),
          _combatant(
            speciesId: 'usable_striker',
            lineupIndex: 2,
            stats: _stats(speed: 70, attack: 90, specialAttack: 90),
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'slash',
                name: 'Slash',
                power: 75,
                category: BattleMoveCategory.physical,
                target: BattleMoveTarget.opponent,
              ),
            ],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.speciesId, equals('usable_striker'));
      expect(afterTurn.state.currentTurn!.switchEvents.single.wasForced, isTrue);
    });

    test(
        'forced replacement choices override stale recharge/charge state on a KO active',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'beam',
              chargeStateId: 'charge',
            ),
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'beam',
              name: 'Beam',
              power: 80,
              category: BattleMoveCategory.special,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'charge',
              ),
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceSwitch>().single.reserveIndex,
          equals(0));

      final afterReplacement =
          session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.playerReserve.single.speciesId,
          equals('fainted_player'));
      expect(
        afterReplacement.state.playerReserve.single.volatileState.hasAny,
        isFalse,
      );
      expect(
        afterReplacement.state.currentTurn!.enemyAction,
        isA<BattleActionNone>(),
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.wasForced,
        isTrue,
      );
      expect(
        afterReplacement.state.currentTurn!.switchEvents.single.side,
        equals(BattleSideId.player),
      );
      expect(
        afterReplacement.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>(),
        hasLength(1),
      );
      expect(afterReplacement.state.currentTurn!.executions, isEmpty);
      expect(afterReplacement.state.currentTurn!.statusEvents, isEmpty);
      expect(afterReplacement.state.currentTurn!.fieldEvents, isEmpty);
    });

    test(
        'forced replacement choices expose only valid switches even when wild capture and run would normally be allowed',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'fainted_player',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceSwitch>(), hasLength(1));
      expect(choices.whereType<PlayerBattleChoiceFight>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceContinue>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('voluntary switch resolves before an opposing attack and redirects it',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 35,
          currentHp: 35,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 50,
            currentHp: 50,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          stats: _stats(speed: 100, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.player.currentHp, lessThan(50));
      expect(
        afterTurn.state.playerReserve.single.speciesId,
        equals('lead_player'),
      );
      expect(
        afterTurn.state.playerReserve.single.currentHp,
        equals(35),
      );
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );
      final timeline = afterTurn.state.currentTurn!.timeline;
      final firstSwitchEvent =
          timeline.whereType<BattleTurnSwitchEvent>().first;
      final enemyExecution =
          timeline.whereType<BattleTurnExecutionEvent>().single;
      expect(firstSwitchEvent.event.side, equals(BattleSideId.player));
      expect(enemyExecution.execution.attacker, equals('enemy'));
      expect(
        timeline.indexOf(firstSwitchEvent),
        lessThan(timeline.indexOf(enemyExecution)),
      );
    });

    test(
        'legacy trainer behavior keeps fighting instead of switching voluntarily',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(null),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          stats: _stats(speed: 80, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 45,
            currentHp: 45,
            stats: _stats(speed: 70, attack: 90),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.enemyAction, isA<BattleActionFight>());
      expect(afterTurn.state.enemy.speciesId, equals('lead_enemy'));
      expect(afterTurn.state.currentTurn!.switchEvents, isEmpty);
    });

    test(
        'wild battles do not opt into voluntary enemy switches even if a richer policy is injected manually',
        () {
      final session = _session(
        isTrainerBattle: false,
        opponentPolicy: battleOpponentPolicyForDifficulty(9),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          stats: _stats(speed: 80, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 45,
            currentHp: 45,
            stats: _stats(speed: 70, attack: 90),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.enemyAction, isA<BattleActionFight>());
      expect(afterTurn.state.enemy.speciesId, equals('lead_enemy'));
      expect(afterTurn.state.currentTurn!.switchEvents, isEmpty);
    });

    test(
        'mid difficulty trainer can switch voluntarily before the player attack when the active is offensively useless',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(5),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          stats: _stats(speed: 80, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 35)],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 45,
            currentHp: 45,
            stats: _stats(speed: 70, attack: 90),
            moves: <BattleMoveData>[_tackle(power: 120)],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.currentTurn!.enemyAction, isA<BattleActionSwitch>());
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterTurn.state.enemy.currentHp, lessThan(45));
      expect(
        afterTurn.state.enemyReserve.single.speciesId,
        equals('lead_enemy'),
      );
      expect(afterTurn.state.currentTurn!.switchEvents, hasLength(1));
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );
      expect(
        afterTurn.state.currentTurn!.switchEvents.single.side,
        equals(BattleSideId.enemy),
      );
      final timeline = afterTurn.state.currentTurn!.timeline;
      final switchEvent = timeline.whereType<BattleTurnSwitchEvent>().single;
      final playerExecution =
          timeline.whereType<BattleTurnExecutionEvent>().single;
      expect(
        timeline.indexOf(switchEvent),
        lessThan(timeline.indexOf(playerExecution)),
      );
      expect(playerExecution.execution.target, equals('enemy'));
    });

    test(
        'high difficulty trainer can bail out a low HP active via a voluntary switch without breaking the next turn',
        () {
      final session = _session(
        isTrainerBattle: true,
        opponentPolicy: battleOpponentPolicyForDifficulty(9),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          stats: _stats(speed: 80, attack: 80),
          moves: <BattleMoveData>[_tackle(power: 20)],
        ),
        enemy: _combatant(
          speciesId: 'doomed_enemy',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 8,
          stats: _stats(speed: 45, attack: 95),
          moves: <BattleMoveData>[_tackle(power: 70)],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'healthy_enemy',
            lineupIndex: 1,
            maxHp: 45,
            currentHp: 45,
            stats: _stats(speed: 95, attack: 90),
            moves: <BattleMoveData>[_tackle(power: 85)],
          ),
        ],
      );

      final afterSwitchTurn =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(
        afterSwitchTurn.state.currentTurn!.enemyAction,
        isA<BattleActionSwitch>(),
      );
      expect(afterSwitchTurn.state.enemy.speciesId, equals('healthy_enemy'));
      expect(
        afterSwitchTurn.state.currentTurn!.switchEvents.single.wasForced,
        isFalse,
      );

      final nextTurn =
          afterSwitchTurn.applyChoice(const PlayerBattleChoiceFight(0));

      expect(nextTurn.state.currentTurn!.enemyAction, isA<BattleActionFight>());
      expect(
        nextTurn.state.currentTurn!.timeline.whereType<BattleTurnSwitchEvent>(),
        isEmpty,
      );
    });

    test('field state survives a voluntary switch turn', () {
      final session = _session(
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterTurn.state.player.speciesId, equals('bench_player'));
      expect(afterTurn.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterTurn.state.field.weather?.remainingTurns,
        equals(2),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterTurn.state.field.pseudoWeather?.remainingTurns,
        equals(2),
      );
    });

    test(
        'switching out resets stages and volatile baggage but keeps hp, pp, and major status while tox counter restarts at 1',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 27,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 4),
          stats: _stats(speed: 80),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'swords_dance',
              name: 'Swords Dance',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              selfStatStageChanges: <BattleStatStageChange>[
                BattleStatStageChange(stat: BattleStatId.attack, stages: 2),
              ],
            ),
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              category: BattleMoveCategory.physical,
              currentPp: 7,
              pp: 35,
            ),
          ],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterBoost = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(afterBoost.state.player.statStages.attack, equals(2));

      final afterSwitchOut =
          afterBoost.applyChoice(const PlayerBattleChoiceSwitch(0));
      final benchedLead = afterSwitchOut.state.playerReserve.singleWhere(
        (combatant) => combatant.speciesId == 'lead_player',
      );
      expect(benchedLead.statStages.attack, equals(0));
      expect(
        benchedLead.currentHp,
        equals(afterBoost.state.player.currentHp),
      );
      expect(benchedLead.moves[1].currentPp, equals(7));
      expect(benchedLead.majorStatus!.id, equals(BattleMajorStatusId.tox));
      expect(benchedLead.majorStatus!.toxicCounter, equals(1));

      final afterSwitchBack =
          afterSwitchOut.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitchBack.state.player.speciesId, equals('lead_player'));
      expect(afterSwitchBack.state.player.statStages.attack, equals(0));
      expect(afterSwitchBack.state.player.moves[1].currentPp, equals(7));
      expect(
        afterSwitchBack.state.currentTurn!.statusEvents
            .where(
              (event) =>
                  event.kind == BattleStatusEventKind.residualDamage &&
                  event.target == 'player',
            )
            .single
            .toxicCounter,
        equals(1),
      );
    });

    test(
        'double KO with reserves on both sides auto-replaces enemy and forces the player to switch',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.player.isFainted, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
      expect(
        afterTurn.state.currentTurn!.switchEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
      expect(
        afterTurn.getAvailableChoices().whereType<PlayerBattleChoiceSwitch>(),
        hasLength(1),
      );
      final switchTimeline = afterTurn.state.currentTurn!.timeline
          .whereType<BattleTurnSwitchEvent>()
          .toList(growable: false);
      expect(
        switchTimeline.map((event) => event.event.kind).toList(growable: false),
        equals(<BattleSwitchEventKind>[
          BattleSwitchEventKind.switched,
          BattleSwitchEventKind.replacementRequired,
        ]),
      );
    });

    test('double KO with only an enemy reserve remains a defeat for the player',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          currentHp: 1,
          majorStatus: const BattleMajorStatusState.psn(),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isDefeat, isTrue);
      expect(afterTurn.state.enemy.speciesId, equals('bench_enemy'));
    });
  });
}

```
