# Phase E — Mini Event / Condition Engine Report

## 1. Résumé exécutif honnête

Verdict global : **Phase E est réellement réussie**, mais dans un sens strictement borné.

Ce qui a vraiment changé :
- `packages/map_battle/lib/src/battle_session.dart` n'est plus l'endroit principal où vivent la majorité des règles déjà supportées pour les statuts majeurs, les volatiles BE8 et le champ BE9.
- un mini engine local, explicite et réellement consommé a été introduit dans `packages/map_battle/lib/src/battle_condition_engine.dart`.
- la boucle réelle du moteur appelle maintenant cet engine à des points d'entrée bornés et lisibles : tentative d'action, interception sur hit, post-résolution de move, continuation forcée et fin de tour.
- la sémantique encore dispersée de `par` et `brn` a été recentralisée après review dans l'engine via des helpers bornés consommés par `BattleSession`.
- un bug réel sur `par + chargeThenStrike` a été corrigé : une paralysie bloquante sur le premier tour de charge ne peut plus armer un faux `pendingCharge`.

Ce qui n'a volontairement pas changé :
- aucun event bus générique.
- aucune vraie queue d'actions enrichie Phase F.
- aucun système de side conditions / slot conditions actives.
- aucune ouverture de `selfSwitch`, `forceSwitch`, abilities, items, doubles, hazards ou terrains riches.
- aucune modification runtime de production n'a été nécessaire.

Pourquoi c'est bien Phase E et pas E/F/H :
- on a déplacé des règles de cycle de vie déjà supportées vers des runners explicites et utilisés réellement.
- on n'a pas introduit de scheduling plus riche ni de taxonomie large d'actions.
- on n'a pas élargi les contrats battle de façon opportuniste.
- on n'a pas ajouté de nouvelles familles de mécaniques pour « rentabiliser » la fondation.

Lecture honnête : ce lot est un **vrai progrès de fondation**, pas un rebranding cosmétique de `BattleSession`, mais il ne prétend pas être un mini-Showdown ni une base générique pour tout le reste.

## 2. Pré-gates exécutés + résultats

### Confirmé par exécution
Pré-gates Git read-only exécutés au début du lot :
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

### État initial interprété honnêtement
Le worktree n'était pas vierge au début de Phase E, car les lots précédents Phase A à D existaient déjà dans l'arbre local. Pour ce lot, le signal utile était :
- aucune écriture Git interdite n'était nécessaire ;
- la surface à toucher pouvait rester contenue à `packages/map_battle` + report ;
- aucun besoin initial confirmé dans `packages/map_runtime`, `examples`, `packages/map_editor` ou `packages/map_core`.

## 3. Méthode réelle utilisée

### Audit
Confirmé par lecture de code :
- lecture des reports Phase A à D demandés par le prompt.
- audit de `battle_session.dart`, `battle_state.dart`, `battle_decision.dart`, `battle_field.dart`, `battle_status.dart`, `battle_volatile.dart`, `battle_switch.dart`, `battle_resolution.dart`.
- audit ciblé des tests battle pertinents (`battle_field_test.dart`, `battle_volatiles_test.dart`, `battle_move_effects_test.dart`, `battle_decision_request_test.dart`, etc.).
- vérification de `battle_overlay_component.dart` pour s'assurer qu'aucune adaptation runtime n'était nécessaire.

### Design
Confirmé par audit + sub-agent :
- choix d'un mini engine local unique dans `battle_condition_engine.dart`.
- refus d'un bus générique, d'un registry de conditions, d'une hiérarchie de callbacks et d'une pseudo queue.
- conservation de `BattleSession` comme orchestrateur du tour.

### Implémentation
Confirmé par lecture de code :
- extraction effective de règles conditionnelles depuis `BattleSession`.
- consommation réelle de l'engine par les code paths de production.

### Tests
Confirmé par exécution :
- red step TDD réel sur le nouveau test `battle_condition_engine_test.dart` avant implémentation.
- suites battle ciblées puis suite battle complète.
- analyze battle complet.
- analyze/test runtime ciblés + smoke Phase A du golden slice.

### Review
Confirmé par exécution + retour sub-agents :
- sub-agent battle-core : `Hilbert`.
- sub-agent scope creep Phase F/G/H : `Averroes`.
- reviewer final séparé : `Confucius`.

## 4. Audit réel avant code

### Où vivait réellement le problème
Confirmé par lecture de code :
- `battle_session.dart` portait encore directement la majorité du cycle de vie des conditions déjà supportées.
- la causalité métier des familles suivantes y restait codée à la main :
  - gate d'action `par`
  - application de statut majeur
  - résiduels `brn` / `psn` / `tox`
  - compteur toxique
  - `protect` / `breakProtect`
  - `mustRecharge` et son tour perdu
  - `chargeThenStrike` (charge + release)
  - `rain` / `sandstorm` / `trickRoom`
  - résiduel météo
  - expiration du champ
  - modificateur météo eau/feu
  - inversion d'ordre via `trickRoom`

### Vrais event points minimaux utiles aujourd'hui
Confirmé par lecture de code et retenu au design :
- tentative d'action : pour `par` + PP + charge start/release.
- interception sur hit : pour `protect` / `breakProtect`.
- post-résolution de move : pour statuts majeurs, weather/pseudoWeather, recharge obligatoire.
- continuation forcée : pour le tour perdu de recharge.
- fin de tour : pour résiduels de statuts, résiduels météo, expiration/progression du champ, nettoyage de `protect`.
- helpers de règles de condition hors boucle :
  - inversion d'ordre par `trickRoom`
  - multiplicateur météo pluie
  - multiplicateur offensif de brûlure
  - malus de vitesse de paralysie

### Faux positifs écartés
Confirmé par lecture de code :
- il n'était ni nécessaire ni sain d'ouvrir une vraie queue d'actions.
- il n'était ni nécessaire ni sain d'ouvrir des side conditions / slot conditions.
- il n'était ni nécessaire ni sain de construire une hiérarchie générique `BattleCondition`.
- il n'était pas utile de toucher le runtime de production : l'overlay consomme déjà les traces de tour sans heuristique supplémentaire.

### Ce qui devait encore rester dans `BattleSession`
Confirmé par lecture de code :
- orchestration du tour.
- modèle de décision Phase C.
- choix illégaux / transitions de requests.
- résolution de l'IA ennemie.
- ordre global des actions.
- hit check, formule de dégâts, crits, STAB, type chart.
- timeline finale et `BattleTurnResult`.
- switches, remplacements, outcome.

## 5. Design retenu

### Structure exacte
Confirmé par lecture de code :
- nouveau fichier : `packages/map_battle/lib/src/battle_condition_engine.dart`
- type principal : `BattleConditionEngine`
- runners explicites réellement consommés :
  - `runActionAttempt(...)`
  - `runHitInterception(...)`
  - `runMoveResolved(...)`
  - `runForcedContinueTurn(...)`
  - `runEndOfTurn(...)`
- helpers bornés consommés par `BattleSession` :
  - `doesFieldInvertSpeedOrder(...)`
  - `resolveFieldDamageMultiplier(...)`
  - `resolveStatusDamageMultiplier(...)`
  - `resolveStatusAdjustedSpeed(...)`
- règles privées internes :
  - `_BattleStatusRules`
  - `_BattleVolatileRules`
  - `_BattleFieldRules`

### Pourquoi ce design
Confirmé par lecture de code + revue :
- assez petit pour rester Phase E.
- assez réel pour que `BattleSession` perde effectivement sa logique conditionnelle la plus dense.
- assez explicite pour éviter les heuristiques et l'effet « wrapper cosmétique ».
- assez borné pour refuser les ouvertures cachées vers F/G/H.

### Ce qui a été refusé
Confirmé par audit/design :
- event bus générique.
- callbacks dynamiques ou registry.
- système de plugin / conditions configurables.
- hiérarchie abstraite future-proof non utilisée.
- vraie queue d'actions.
- side/slot conditions actives.
- refactor runtime préventif.

## 6. Critique explicite du prompt

### Ce qui était juste
- le prompt poussait correctement à éviter un faux mini-Showdown.
- le prompt identifiait bien que `battle_session.dart` portait encore trop de causalité conditionnelle.
- le prompt insistait à raison sur la migration du sous-ensemble déjà supporté avant toute nouvelle feature.

### Ce qui était discutable
- la liste « mécaniques déjà supportées à faire passer par le nouveau système » pouvait laisser croire qu'il fallait absolument sortir toute la sémantique de `par` et `brn` des calculs auxiliaires, même si une partie n'était pas directement un event point. La review a montré qu'il fallait effectivement recentraliser `par`/`brn`, mais via helpers bornés, pas via faux événements.
- le prompt parlait de « quelques event points » comme si tout devait forcément passer par des runners événementiels. En pratique, certaines règles de condition déjà supportées vivent plus honnêtement comme helpers déterministes (`trickRoom`, pluie, brûlure, paralysie vitesse) que comme pseudo-événements.

### Ce qui aurait été dangereux si suivi aveuglément
- transformer toute règle de condition en pseudo événement pour « faire engine » aurait poussé vers un faux framework.
- vouloir faire sortir tout le champ sémantique de `BattleSession` sans nuance aurait risqué d'ouvrir une micro-Phase F.

### Recadrage retenu
- garder des event points explicites là où il y a réellement un cycle de vie.
- garder quelques helpers de condition là où il s'agit d'un calcul borné déjà consommé.
- refuser toute abstraction sans consommation immédiate.

## 7. Périmètre inclus / exclu

### Inclus
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_condition_engine_test.dart`
- `packages/map_battle/test/battle_volatiles_test.dart`
- report final sous `reports/`

### Exclus volontairement
- `packages/map_runtime/**` en production
- `examples/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- toute mécanique nouvelle hors sous-ensemble déjà supporté
- queue d'actions Phase F
- expansion large de contrats Phase G
- mécaniques riches Phase H

### Justification du non-changement runtime
Confirmé par lecture de code + exécution :
- aucune adaptation runtime n'était strictement nécessaire.
- l'overlay existant reste compatible parce que la forme de `BattleTurnResult` et des requests n'a pas été cassée.
- le smoke golden slice est resté vert sans toucher le runtime.

## 8. Plan local retenu

1. auditer les règles conditionnelles déjà supportées et les reports Phase A à D.
2. demander deux audits séparés : battle-core et scope creep.
3. écrire un test rouge pour le nouvel engine.
4. introduire un mini engine unique et l'intégrer aux vrais points d'entrée de `BattleSession`.
5. migrer hors de `BattleSession` la logique de statuts/volatiles/field réellement supportée.
6. relancer analyze/tests battle ciblés.
7. faire la review séparée.
8. corriger les findings valides.
9. relancer analyze/tests battle complets + runtime + smoke.
10. produire le report final.

## 9. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_condition_engine.dart`
Créé.

Pourquoi :
- donner un vrai lieu de vie aux règles de cycle de vie des conditions déjà supportées.
- porter des runners explicites réellement appelés par le moteur.
- rendre Phase E réelle au lieu de laisser `BattleSession` tout porter.

### `packages/map_battle/lib/src/battle_session.dart`
Modifié.

Pourquoi :
- brancher le moteur sur l'engine Phase E.
- supprimer la majeure partie de la logique conditionnelle déjà supportée qui vivait en dur.
- conserver `BattleSession` dans son rôle d'orchestrateur.

### `packages/map_battle/test/battle_condition_engine_test.dart`
Créé.

Pourquoi :
- tester directement les runners Phase E et leurs helpers bornés.
- verrouiller la réalité du nouvel engine au niveau unitaire.

### `packages/map_battle/test/battle_volatiles_test.dart`
Modifié.

Pourquoi :
- couvrir le bug réel remonté en review : `par + chargeThenStrike` ne doit pas armer une fausse charge.
- prouver que la frontière engine/session reste honnête sur un cas d'intégration.

## 10. Classification des blockers réellement adressés

### Blockers réellement adressés par Phase E
Confirmé par lecture de code :
- `BattleSession` n'est plus le dépôt principal de la logique conditionnelle supportée.
- les familles `status` / `volatile` / `field` ont maintenant un cycle de vie plus lisible.
- `par` et `brn` ne sont plus sémantiquement répartis entre engine et session.
- la tentative d'action et la fin de tour ont maintenant des seams explicites.

### Blockers explicitement non adressés
Confirmé par lecture de code :
- queue d'actions enrichie.
- système de conditions side/slot.
- event engine générique.
- selfSwitch / forceSwitch.
- side conditions / hazards / terrains riches.
- abilities / items / doubles.

## 11. Commandes réellement exécutées

### Git read-only
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

### Audit lecture seule
- lectures ciblées des reports Phase A à D
- lectures ciblées de `map_battle` et d'un unique fichier runtime de compatibilité

### TDD / validation battle
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_condition_engine_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart format lib/src/battle_condition_engine.dart lib/src/battle_session.dart test/battle_condition_engine_test.dart test/battle_volatiles_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_condition_engine_test.dart test/battle_volatiles_test.dart test/battle_field_test.dart test/battle_move_effects_test.dart test/battle_decision_request_test.dart test/battle_switch_test.dart test/battle_session_flow_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`

### Validation runtime / smoke
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/presentation/flame/battle_overlay_component.dart test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`

### Review / sub-agents
- audit/design battle-core via sub-agent `Hilbert`
- audit scope creep via sub-agent `Averroes`
- review finale séparée via `Confucius`

## 12. Résultats réels

### Format
Confirmé par exécution :
- format battle relancé sur les fichiers touchés
- résultat final : vert

### Analyze
Confirmé par exécution :
- `packages/map_battle`: vert (`No issues found!`)
- `packages/map_runtime` ciblé : vert (`No issues found!`)

### Tests
Confirmé par exécution :
- test rouge initial Phase E : `battle_condition_engine_test.dart` cassait honnêtement avant implémentation
- suites battle ciblées après implémentation : vert
- suite battle complète : vert
- tests runtime ciblés : vert

### Smoke produit
Confirmé par exécution :
- smoke Phase A golden slice : vert via `phase_a_golden_battle_slice_smoke_test.dart`
- wild battle du golden slice : vert
- trainer battle du golden slice : vert

## 13. Incidents rencontrés

### Reviewer P1
Un vrai bug a été trouvé en review :
- `par + chargeThenStrike` pouvait armer un faux `pendingCharge` au premier tour de charge.

Décision : corrigé.

### Reviewer P2
La review a aussi signalé que `par` et `brn` restaient partiellement dans `BattleSession`.

Décision : remarque retenue, recentralisation bornée ajoutée dans l'engine via `resolveStatusDamageMultiplier` et `resolveStatusAdjustedSpeed`.

### Outillage Flutter
Confirmé par exécution :
- `flutter analyze` a brièvement attendu le startup lock pendant qu'un autre process Flutter tournait.
- ce n'était pas un problème de code, seulement un incident d'outillage transitoire.
- les deux commandes ont ensuite fini proprement en vert.

## 14. Décisions retenues / rejetées

### Retenues
- un seul fichier engine Phase E au lieu d'une dispersion artificielle.
- runners explicites + helpers bornés.
- `BattleSession` reste orchestrateur.
- correction locale du bug `par + chargeThenStrike` même si le bug préexistait à l'extraction complète de Phase E.

### Rejetées
- event bus générique.
- registry ou taxonomie abstraite de conditions.
- vraie queue d'actions.
- ouverture side/slot conditions.
- toucher le runtime par confort.

## 15. Retour du sub-agent d’audit/design

### `Hilbert` — battle-core
Retours principaux retenus :
- les vrais event points minimaux sont `actionAttempt`, `hitInterception`, `moveResolved`, `forcedContinueTurn`, `endOfTurn`.
- `BattleSession` devait garder l'orchestration, le damage pipeline, la timeline, les switches et l'outcome.
- il fallait éviter un faux moteur générique.

Ce que j'ai retenu :
- pratiquement tout le cadrage architectural.

Ce que j'ai rejeté :
- rien de substantiel ; son cadrage correspondait au design retenu.

### `Averroes` — risques de scope creep
Retours principaux retenus :
- ne pas ouvrir de pseudo queue.
- ne pas ajouter de registry ou de `BattleCondition` générique.
- ne pas faire vivre switches/replacements/requests dans l'engine.
- ne pas introduire side/slot conditions ni terrains/hazards.

Ce que j'ai retenu :
- tout le cadrage de frontière.

Ce que j'ai rejeté :
- rien de substantiel ; les garde-fous ont été suivis.

## 16. Retour du reviewer séparé

Reviewer final : `Confucius`

### Finding retenu `[P1]`
- un move à charge pouvait être armé malgré une paralysie bloquante.
- gravité : réelle, dans le sous-ensemble explicitement supporté.
- décision : corrigé.

### Finding retenu `[P2]`
- la frontière Phase E était réelle mais encore incomplète car `brn` et `par` restaient partiellement dans `BattleSession`.
- décision : retenu et corrigé de manière bornée.

### Ce qui a été explicitement écarté
- le reviewer n'a pas trouvé de creep majeur vers F/G/H.
- aucun finding majeur supplémentaire sur le runtime ou la topologie Phase D.

## 17. Corrections appliquées après review

1. correction du cycle `chargeThenStrike` :
- la préparation volatile ne pose plus `pendingCharge` avant que le gate `par` ait été passé.
- le moteur peut encore consommer les PP honnêtement sur une tentative bloquée.
- le tour suivant n'est plus faussement forcé en `continue` après une paralysie bloquante sur le premier tour de charge.

2. recentralisation de `par` / `brn` :
- `BattleSession._computeMoveDamage(...)` passe maintenant par `resolveStatusDamageMultiplier(...)`.
- `BattleSession._resolveEffectiveSpeed(...)` passe maintenant par `resolveStatusAdjustedSpeed(...)`.

3. couverture de tests renforcée :
- nouveau test unitaire engine pour `brn`.
- nouveau test unitaire engine pour `par`.
- nouveau test d'intégration session pour `par + chargeThenStrike`.

## 18. Autocritique finale

### Ce que le lot réussit vraiment
- il rend enfin la frontière des conditions tangible et réellement utilisée.
- il réduit fortement la densité causale de `BattleSession`.
- il prépare honnêtement Phase F en clarifiant déjà quels moments du tour ont une sémantique conditionnelle distincte.

### Ce qu'il ne faut pas sur-vendre
- ce n'est toujours pas un engine générique de conditions.
- ce n'est toujours pas un scheduler ou une queue.
- ce n'est toujours pas une architecture Showdown-like.
- des règles centrales restent forcément dans `BattleSession` tant que F n'existe pas.

### Risques restants
- certaines logiques de tour resteront encore mécaniquement couplées à `BattleSession` tant que la résolution globale et son ordonnancement ne sont pas revus en Phase F.
- l'engine reste volontairement petit ; si quelqu'un commence à y empiler des cas hors scope sans gate, il se dégradera vite.

### Zones d'incertitude restantes
- point incertain raisonnable : le comportement idéal d'une paralysie bloquante sur la **libération** d'un move déjà chargé n'a pas été rouvert dans ce lot. Le bug confirmé concernait l'armement initial d'une charge. Le comportement de libération reste celui du moteur historique et n'a pas été étendu ici pour ne pas rouvrir un chantier de sémantique plus large.

## 19. Contenu complet de tous les fichiers touchés

### `packages/map_battle/lib/src/battle_condition_engine.dart`

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';

const Set<String> _sandstormResidualImmuneTypes = <String>{
  'ground',
  'rock',
  'steel',
};

/// Mini event / condition engine réellement consommé par le moteur singles.
///
/// Frontière Phase E volontairement stricte :
/// - ce n'est pas un bus d'événements générique ;
/// - ce n'est pas une queue d'actions ;
/// - ce n'est pas un registry Showdown-like ;
/// - ce n'est pas une taxonomie universelle de callbacks.
///
/// Ce type sert uniquement à sortir de `battle_session.dart` les règles
/// conditionnelles déjà réellement supportées aujourd'hui :
/// - statuts majeurs (`par`, `brn`, `psn`, `tox`) ;
/// - volatiles BE8 (`protect`, recharge, charge then strike) ;
/// - field BE9 (`rain`, `sandstorm`, `trickRoom`).
///
/// Les event points exposés sont explicites et bornés :
/// - [runActionAttempt]
/// - [runHitInterception]
/// - [runMoveResolved]
/// - [runForcedContinueTurn]
/// - [runEndOfTurn]
///
/// `BattleSession` reste l'orchestrateur du tour. Cet engine ne pilote ni les
/// requests, ni les switches, ni l'outcome, ni l'ordre global des actions.
final class BattleConditionEngine {
  const BattleConditionEngine();

  static const _statusRules = _BattleStatusRules();
  static const _volatileRules = _BattleVolatileRules();
  static const _fieldRules = _BattleFieldRules();

  /// Résout les conditions qui s'appliquent à une tentative d'action.
  ///
  /// Ordre volontairement figé pour le sous-ensemble actuel :
  /// 1. consommation honnête des PP ou libération locale d'une charge pendante ;
  /// 2. gate de statut majeur (`par`) ;
  /// 3. éventuelle entrée en charge pour un move sur deux tours ;
  /// 4. émission des événements visibles associés.
  BattleActionAttemptResult runActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleRng rng,
  }) {
    final preparation = _volatileRules.prepareActionAttempt(
      attackerLabel: attackerLabel,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
    );
    final actionGate = _statusRules.runActionAttemptGate(
      combatantLabel: attackerLabel,
      combatant: preparation.attacker,
      rng: rng,
    );

    if (!actionGate.canAct) {
      return BattleActionAttemptResult(
        outcome: BattleActionAttemptOutcome.preventedAction,
        attacker: preparation.attacker,
        rng: actionGate.nextRng,
        statusEvents: actionGate.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    final continuation = _volatileRules.finalizeActionAttempt(
      attackerLabel: attackerLabel,
      move: move,
      moveIndex: moveIndex,
      preparedAttacker: preparation.attacker,
      preparedChargeRelease: preparation.preparedChargeRelease,
      canStartCharge: preparation.canStartCharge,
    );

    if (continuation.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return BattleActionAttemptResult(
        outcome: BattleActionAttemptOutcome.chargeStarted,
        attacker: continuation.attacker,
        rng: actionGate.nextRng,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: continuation.volatileEvents,
      );
    }

    return BattleActionAttemptResult(
      outcome: BattleActionAttemptOutcome.proceed,
      attacker: continuation.attacker,
      rng: actionGate.nextRng,
      statusEvents: const <BattleStatusEvent>[],
      volatileEvents: continuation.volatileEvents,
    );
  }

  /// Résout les interceptions volatiles après le hit check.
  ///
  /// Frontière actuelle :
  /// - `protect` / `breakProtect` seulement ;
  /// - aucune autre interception, semi-invulnérabilité ou callback générique.
  BattleHitInterceptionResult runHitInterception({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    return _volatileRules.runHitInterception(
      move: move,
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: attacker,
      defender: defender,
    );
  }

  /// Résout les conditions qui s'appliquent après la résolution principale.
  ///
  /// Aujourd'hui cela couvre exactement :
  /// - application de statut majeur par move ;
  /// - pose / retrait de weather ou pseudoWeather ;
  /// - pose d'une recharge obligatoire.
  BattleMoveResolvedConditionResult runMoveResolved({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required bool wasImmune,
    required BattleRng rng,
  }) {
    final statusApplication = _statusRules.runMoveResolved(
      move: move,
      targetLabel: targetLabel,
      defender: defender,
      wasImmune: wasImmune,
      rng: rng,
    );
    final fieldApplication = _fieldRules.runMoveResolved(
      move: move,
      field: field,
    );
    final volatileFollowUp = _volatileRules.runMoveResolved(
      move: move,
      attackerLabel: attackerLabel,
      attacker: attacker,
      wasImmune: wasImmune,
    );

    return BattleMoveResolvedConditionResult(
      attacker: volatileFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      statusEvents: statusApplication.statusEvents,
      volatileEvents: volatileFollowUp.volatileEvents,
      fieldEvents: fieldApplication.fieldEvents,
    );
  }

  /// Résout un tour forcé de continuation.
  ///
  /// Phase E n'ouvre ici qu'un seul cas réellement vivant :
  /// - le tour perdu par recharge.
  BattleForcedContinueTurnResult runForcedContinueTurn({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    return _volatileRules.runForcedContinueTurn(
      combatantLabel: combatantLabel,
      combatant: combatant,
    );
  }

  /// Résout la phase de fin de tour des conditions déjà supportées.
  ///
  /// Ordre conservé explicitement :
  /// 1. résiduels de statuts majeurs ;
  /// 2. résiduels météo ;
  /// 3. progression / expiration du champ ;
  /// 4. nettoyage des flags volatiles transitoires de fin de tour.
  BattleEndOfTurnConditionResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final statusResiduals = _statusRules.runEndOfTurn(
      player: player,
      enemy: enemy,
    );
    final fieldResiduals = _fieldRules.runEndOfTurn(
      player: statusResiduals.player,
      enemy: statusResiduals.enemy,
      field: field,
    );

    return BattleEndOfTurnConditionResult(
      player: _volatileRules.clearEndOfTurnFlags(fieldResiduals.player),
      enemy: _volatileRules.clearEndOfTurnFlags(fieldResiduals.enemy),
      field: fieldResiduals.field,
      statusEvents: statusResiduals.statusEvents,
      fieldEvents: fieldResiduals.fieldEvents,
    );
  }

  /// Retourne `true` si le champ inverse l'ordre de vitesse.
  ///
  /// Ce seam reste volontairement minuscule :
  /// - il évite que `BattleSession` relise directement `trickRoom` ;
  /// - il n'ouvre pas un système générique de modificateurs d'initiative.
  bool doesFieldInvertSpeedOrder(BattleFieldState field) {
    return _fieldRules.doesFieldInvertSpeedOrder(field);
  }

  /// Retourne le multiplicateur météo local réellement supporté.
  ///
  /// Phase E l'extrait hors de `BattleSession` parce que c'est bien une règle
  /// de condition de champ, pas une partie de la formule de dégâts pure.
  double resolveFieldDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    return _fieldRules.resolveFieldDamageMultiplier(
      move: move,
      field: field,
    );
  }

  /// Retourne le multiplicateur de dégâts induit par un statut majeur.
  ///
  /// Frontière volontairement bornée :
  /// - seule la brûlure sur moves physiques vit ici aujourd'hui ;
  /// - aucun autre modificateur offensif conditionnel n'est inventé ;
  /// - la formule complète de dégâts reste orchestrée par `BattleSession`.
  double resolveStatusDamageMultiplier({
    required BattleMove move,
    required BattleCombatant attacker,
  }) {
    return _statusRules.resolveDamageMultiplier(
      move: move,
      attacker: attacker,
    );
  }

  /// Applique le ralentissement de statut à une vitesse déjà stage-résolue.
  ///
  /// Cet engine ne remplace pas le calcul de stat de `BattleSession` :
  /// - la session garde le snapshot runtime + les stages ;
  /// - l'engine consomme seulement la partie réellement "condition" ;
  /// - aujourd'hui cela signifie le malus simple de paralysie.
  int resolveStatusAdjustedSpeed({
    required BattleCombatant combatant,
    required int stagedSpeed,
  }) {
    return _statusRules.resolveAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
    );
  }
}

enum BattleActionAttemptOutcome {
  proceed,
  preventedAction,
  chargeStarted,
}

final class BattleActionAttemptResult {
  const BattleActionAttemptResult({
    required this.outcome,
    required this.attacker,
    required this.rng,
    required this.statusEvents,
    required this.volatileEvents,
  });

  final BattleActionAttemptOutcome outcome;
  final BattleCombatant attacker;
  final BattleRng rng;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleHitInterceptionResult {
  const BattleHitInterceptionResult({
    required this.attacker,
    required this.defender,
    required this.blockedByProtect,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final bool blockedByProtect;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleMoveResolvedConditionResult {
  const BattleMoveResolvedConditionResult({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
}

final class BattleForcedContinueTurnResult {
  const BattleForcedContinueTurnResult({
    required this.combatant,
    required this.volatileEvents,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
}

final class BattleEndOfTurnConditionResult {
  const BattleEndOfTurnConditionResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.statusEvents,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleFieldEvent> fieldEvents;
}

final class _BattleStatusRules {
  const _BattleStatusRules();

  _StatusActionGateResult runActionAttemptGate({
    required String combatantLabel,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    final status = combatant.majorStatus;
    if (status?.id != BattleMajorStatusId.par) {
      return _StatusActionGateResult(
        canAct: true,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final roll = rng.nextChance(
      numerator: 1,
      denominator: 4,
    );
    if (!roll.didOccur) {
      return _StatusActionGateResult(
        canAct: true,
        nextRng: roll.next,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    return _StatusActionGateResult(
      canAct: false,
      nextRng: roll.next,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.preventedAction(
          target: combatantLabel,
          status: BattleMajorStatusId.par,
        ),
      ],
    );
  }

  _StatusMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required String targetLabel,
    required BattleCombatant defender,
    required bool wasImmune,
    required BattleRng rng,
  }) {
    final effect = move.majorStatusEffect;
    if (effect == null) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (wasImmune && move.resolvedCategory != BattleMoveCategory.status) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (defender.majorStatus != null) {
      return _StatusMoveResolvedResult(
        defender: defender,
        nextRng: rng,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.blockedExistingMajorStatus(
            target: targetLabel,
            status: effect.status,
            existingStatus: defender.majorStatus!.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    if (effect.chancePercent case final chance?) {
      final chanceRoll = rng.nextChance(
        numerator: chance,
        denominator: 100,
      );
      if (!chanceRoll.didOccur) {
        return _StatusMoveResolvedResult(
          defender: defender,
          nextRng: chanceRoll.next,
          statusEvents: const <BattleStatusEvent>[],
        );
      }

      return _StatusMoveResolvedResult(
        defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
        nextRng: chanceRoll.next,
        statusEvents: <BattleStatusEvent>[
          BattleStatusEvent.applied(
            target: targetLabel,
            status: effect.status,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _StatusMoveResolvedResult(
      defender: defender.withMajorStatus(_majorStatusStateFor(effect.status)),
      nextRng: rng,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.applied(
          target: targetLabel,
          status: effect.status,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _StatusEndOfTurnResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    final playerResidual = !player.isFainted
        ? _applyResidualForCombatant(
            combatant: player,
            combatantLabel: 'player',
          )
        : _SingleStatusResidual(
            combatant: player,
            statusEvents: const <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyResidualForCombatant(
            combatant: enemy,
            combatantLabel: 'enemy',
          )
        : _SingleStatusResidual(
            combatant: enemy,
            statusEvents: const <BattleStatusEvent>[],
          );

    return _StatusEndOfTurnResult(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      statusEvents: <BattleStatusEvent>[
        ...playerResidual.statusEvents,
        ...enemyResidual.statusEvents,
      ],
    );
  }

  _SingleStatusResidual _applyResidualForCombatant({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    final status = combatant.majorStatus;
    if (status == null || combatant.isFainted) {
      return _SingleStatusResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final residualDamage = switch (status.id) {
      BattleMajorStatusId.par => 0,
      BattleMajorStatusId.brn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 16,
        ),
      BattleMajorStatusId.psn => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: 1,
          denominator: 8,
        ),
      BattleMajorStatusId.tox => _fractionalResidual(
          maxHp: combatant.maxHp,
          numerator: status.toxicCounter,
          denominator: 16,
        ),
    };

    if (residualDamage <= 0) {
      return _SingleStatusResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final damagedCombatant = combatant.withDamage(residualDamage);
    final nextCombatant =
        status.id == BattleMajorStatusId.tox && !damagedCombatant.isFainted
            ? damagedCombatant.withMajorStatus(status.incrementToxicCounter())
            : damagedCombatant;

    return _SingleStatusResidual(
      combatant: nextCombatant,
      statusEvents: <BattleStatusEvent>[
        BattleStatusEvent.residualDamage(
          target: combatantLabel,
          status: status.id,
          damage: residualDamage,
          toxicCounter:
              status.id == BattleMajorStatusId.tox ? status.toxicCounter : null,
        ),
      ],
    );
  }

  BattleMajorStatusState _majorStatusStateFor(BattleMajorStatusId status) {
    return switch (status) {
      BattleMajorStatusId.par => const BattleMajorStatusState.par(),
      BattleMajorStatusId.brn => const BattleMajorStatusState.brn(),
      BattleMajorStatusId.psn => const BattleMajorStatusState.psn(),
      BattleMajorStatusId.tox => const BattleMajorStatusState.tox(),
    };
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
  }

  double resolveDamageMultiplier({
    required BattleMove move,
    required BattleCombatant attacker,
  }) {
    if (attacker.majorStatus?.id != BattleMajorStatusId.brn ||
        move.resolvedCategory != BattleMoveCategory.physical) {
      return 1.0;
    }
    return 0.5;
  }

  int resolveAdjustedSpeed({
    required BattleCombatant combatant,
    required int stagedSpeed,
  }) {
    if (combatant.majorStatus?.id != BattleMajorStatusId.par) {
      return stagedSpeed;
    }

    final slowedSpeed = (stagedSpeed * 0.5).floor();
    return slowedSpeed < 1 ? 1 : slowedSpeed;
  }
}

final class _BattleVolatileRules {
  const _BattleVolatileRules();

  /// Prépare l'action volatile avant le gate de statut.
  ///
  /// Frontière importante :
  /// - on peut consommer les PP d'une tentative honnête même si `par` bloque ;
  /// - en revanche on ne doit pas armer une nouvelle charge tant que l'action
  ///   n'a pas réellement passé le gate de statut ;
  /// - cette nuance évite de créer un faux `pendingCharge` sur un tour où le
  ///   move n'a jamais vraiment commencé.
  _VolatileActionPreparation prepareActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
  }) {
    final pendingCharge = attacker.volatileState.pendingCharge;
    final isChargeRelease = pendingCharge != null &&
        pendingCharge.moveIndex == moveIndex &&
        pendingCharge.moveId == move.id;

    if (!isChargeRelease && !move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    final attackerAfterChargeClear = isChargeRelease
        ? attacker.withVolatileState(
            attacker.volatileState.withPendingCharge(null),
          )
        : attacker;
    final attackerAfterPpUse = isChargeRelease
        ? attackerAfterChargeClear
        : attackerAfterChargeClear.withUpdatedMoveAt(
            moveIndex,
            move.withConsumedPp(),
          );

    return _VolatileActionPreparation(
      attacker: attackerAfterPpUse,
      preparedChargeRelease: isChargeRelease
          ? _PreparedChargeRelease(
              moveId: move.id,
              chargeStateId: pendingCharge.chargeStateId,
            )
          : null,
      canStartCharge:
          isChargeRelease ? null : move.chargeThenStrikeEffect?.chargeStateId,
    );
  }

  _VolatileActionContinuation finalizeActionAttempt({
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant preparedAttacker,
    required _PreparedChargeRelease? preparedChargeRelease,
    required String? canStartCharge,
  }) {
    if (canStartCharge case final chargeStateId?) {
      final chargingAttacker = preparedAttacker.withVolatileState(
        preparedAttacker.volatileState.withPendingCharge(
          BattlePendingChargeState(
            moveIndex: moveIndex,
            moveId: move.id,
            chargeStateId: chargeStateId,
          ),
        ),
      );

      return _VolatileActionContinuation(
        outcome: BattleActionAttemptOutcome.chargeStarted,
        attacker: chargingAttacker,
        volatileEvents: <BattleVolatileEvent>[
          BattleVolatileEvent.chargeStarted(
            actor: attackerLabel,
            sourceMoveId: move.id,
            chargeStateId: chargeStateId,
          ),
        ],
      );
    }

    return _VolatileActionContinuation(
      outcome: BattleActionAttemptOutcome.proceed,
      attacker: preparedAttacker,
      volatileEvents: <BattleVolatileEvent>[
        if (preparedChargeRelease case final release?)
          BattleVolatileEvent.chargeReleased(
            actor: attackerLabel,
            sourceMoveId: release.moveId,
            chargeStateId: release.chargeStateId,
          ),
      ],
    );
  }

  BattleHitInterceptionResult runHitInterception({
    required BattleMove move,
    required String attackerLabel,
    required String targetLabel,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    var updatedAttacker = attacker;
    var updatedDefender = defender;
    final volatileEvents = <BattleVolatileEvent>[];

    if (move.selfVolatileStatus == BattleVolatileStatusId.protect) {
      updatedAttacker = updatedAttacker.withVolatileState(
        updatedAttacker.volatileState.withProtectActive(true),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectActivated(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.target != BattleMoveTarget.opponent ||
        !updatedDefender.volatileState.protectActive) {
      return BattleHitInterceptionResult(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    if (move.breaksProtect) {
      updatedDefender = updatedDefender.withVolatileState(
        updatedDefender.volatileState.withProtectActive(false),
      );
      volatileEvents.add(
        BattleVolatileEvent.protectBroken(
          actor: attackerLabel,
          target: targetLabel,
          sourceMoveId: move.id,
        ),
      );
      return BattleHitInterceptionResult(
        attacker: updatedAttacker,
        defender: updatedDefender,
        blockedByProtect: false,
        volatileEvents: volatileEvents,
      );
    }

    volatileEvents.add(
      BattleVolatileEvent.protectBlocked(
        actor: attackerLabel,
        target: targetLabel,
        sourceMoveId: move.id,
      ),
    );
    return BattleHitInterceptionResult(
      attacker: updatedAttacker,
      defender: updatedDefender,
      blockedByProtect: true,
      volatileEvents: volatileEvents,
    );
  }

  _VolatileMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required String attackerLabel,
    required BattleCombatant attacker,
    required bool wasImmune,
  }) {
    if (!move.requiresRecharge ||
        move.resolvedCategory == BattleMoveCategory.status ||
        wasImmune) {
      return _VolatileMoveResolvedResult(
        attacker: attacker,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _VolatileMoveResolvedResult(
      attacker: attacker.withVolatileState(
        attacker.volatileState.withMustRecharge(true),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeRequired(
          actor: attackerLabel,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  BattleForcedContinueTurnResult runForcedContinueTurn({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (!combatant.volatileState.mustRecharge) {
      return BattleForcedContinueTurnResult(
        combatant: combatant,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return BattleForcedContinueTurnResult(
      combatant: combatant.withVolatileState(
        combatant.volatileState.withMustRecharge(false),
      ),
      volatileEvents: <BattleVolatileEvent>[
        BattleVolatileEvent.rechargeTurnSpent(
          actor: combatantLabel,
        ),
      ],
    );
  }

  BattleCombatant clearEndOfTurnFlags(BattleCombatant combatant) {
    final cleared = combatant.volatileState.clearedEndOfTurnFlags();
    if (identical(cleared, combatant.volatileState)) {
      return combatant;
    }
    return combatant.withVolatileState(cleared);
  }
}

final class _BattleFieldRules {
  const _BattleFieldRules();

  _FieldMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    if (move.weatherEffect == null && move.pseudoWeatherEffect == null) {
      return _FieldMoveResolvedResult(
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (move.weatherEffect case final weather?) {
      updatedField = updatedField.withWeather(
        BattleWeatherState(
          id: weather,
          remainingTurns: 5,
        ),
      );
      fieldEvents.add(
        BattleFieldEvent.weatherSet(
          weather: weather,
          sourceMoveId: move.id,
        ),
      );
    }

    if (move.pseudoWeatherEffect case final pseudoWeather?) {
      if (updatedField.pseudoWeather?.id == pseudoWeather) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherCleared(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      } else {
        updatedField = updatedField.withPseudoWeather(
          BattlePseudoWeatherState(
            id: pseudoWeather,
            remainingTurns: 5,
          ),
        );
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherSet(
            pseudoWeather: pseudoWeather,
            sourceMoveId: move.id,
          ),
        );
      }
    }

    return _FieldMoveResolvedResult(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _FieldEndOfTurnResult runEndOfTurn({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weatherResiduals = _applyWeatherResiduals(
      player: player,
      enemy: enemy,
      field: field,
    );
    final fieldProgression = _advanceField(weatherResiduals.field);

    return _FieldEndOfTurnResult(
      player: weatherResiduals.player,
      enemy: weatherResiduals.enemy,
      field: fieldProgression.field,
      fieldEvents: <BattleFieldEvent>[
        ...weatherResiduals.fieldEvents,
        ...fieldProgression.fieldEvents,
      ],
    );
  }

  bool doesFieldInvertSpeedOrder(BattleFieldState field) {
    return field.isPseudoWeatherActive(BattlePseudoWeatherId.trickRoom);
  }

  double resolveFieldDamageMultiplier({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.rain) {
      return 1.0;
    }

    return switch (move.type) {
      'water' => 1.5,
      'fire' => 0.5,
      _ => 1.0,
    };
  }

  _WeatherResidualResult _applyWeatherResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.sandstorm) {
      return _WeatherResidualResult(
        player: player,
        enemy: enemy,
        field: field,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final playerResidual = _applySandstormResidual(
      combatant: player,
      combatantLabel: 'player',
    );
    final enemyResidual = _applySandstormResidual(
      combatant: enemy,
      combatantLabel: 'enemy',
    );

    return _WeatherResidualResult(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      field: field,
      fieldEvents: <BattleFieldEvent>[
        ...playerResidual.fieldEvents,
        ...enemyResidual.fieldEvents,
      ],
    );
  }

  _SandstormResidualResult _applySandstormResidual({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    if (combatant.isFainted || _isImmuneToSandstormResidual(combatant)) {
      return _SandstormResidualResult(
        combatant: combatant,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damage = _fractionalResidual(
      maxHp: combatant.maxHp,
      numerator: 1,
      denominator: 16,
    );

    return _SandstormResidualResult(
      combatant: combatant.withDamage(damage),
      fieldEvents: <BattleFieldEvent>[
        BattleFieldEvent.weatherResidualDamage(
          weather: BattleWeatherId.sandstorm,
          target: combatantLabel,
          damage: damage,
        ),
      ],
    );
  }

  bool _isImmuneToSandstormResidual(BattleCombatant combatant) {
    final typing = combatant.typing;
    if (typing == null) {
      return false;
    }
    return _sandstormResidualImmuneTypes.contains(typing.primaryType) ||
        (typing.secondaryType != null &&
            _sandstormResidualImmuneTypes.contains(typing.secondaryType));
  }

  _FieldProgressionResult _advanceField(BattleFieldState field) {
    var updatedField = field;
    final fieldEvents = <BattleFieldEvent>[];

    if (field.weather case final weather?) {
      if (weather.remainingTurns <= 1) {
        updatedField = updatedField.withWeather(null);
        fieldEvents.add(
          BattleFieldEvent.weatherExpired(
            weather: weather.id,
          ),
        );
      } else {
        updatedField = updatedField.withWeather(weather.decrement());
      }
    }

    if (field.pseudoWeather case final pseudoWeather?) {
      if (pseudoWeather.remainingTurns <= 1) {
        updatedField = updatedField.withPseudoWeather(null);
        fieldEvents.add(
          BattleFieldEvent.pseudoWeatherExpired(
            pseudoWeather: pseudoWeather.id,
          ),
        );
      } else {
        updatedField =
            updatedField.withPseudoWeather(pseudoWeather.decrement());
      }
    }

    return _FieldProgressionResult(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  int _fractionalResidual({
    required int maxHp,
    required int numerator,
    required int denominator,
  }) {
    final raw = (maxHp * numerator) ~/ denominator;
    return raw < 1 ? 1 : raw;
  }
}

final class _StatusActionGateResult {
  const _StatusActionGateResult({
    required this.canAct,
    required this.nextRng,
    required this.statusEvents,
  });

  final bool canAct;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

final class _StatusMoveResolvedResult {
  const _StatusMoveResolvedResult({
    required this.defender,
    required this.nextRng,
    required this.statusEvents,
  });

  final BattleCombatant defender;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

final class _StatusEndOfTurnResult {
  const _StatusEndOfTurnResult({
    required this.player,
    required this.enemy,
    required this.statusEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final List<BattleStatusEvent> statusEvents;
}

final class _SingleStatusResidual {
  const _SingleStatusResidual({
    required this.combatant,
    required this.statusEvents,
  });

  final BattleCombatant combatant;
  final List<BattleStatusEvent> statusEvents;
}

final class _VolatileActionPreparation {
  const _VolatileActionPreparation({
    required this.attacker,
    required this.preparedChargeRelease,
    required this.canStartCharge,
  });

  final BattleCombatant attacker;
  final _PreparedChargeRelease? preparedChargeRelease;
  final String? canStartCharge;
}

final class _PreparedChargeRelease {
  const _PreparedChargeRelease({
    required this.moveId,
    required this.chargeStateId,
  });

  final String moveId;
  final String? chargeStateId;
}

final class _VolatileActionContinuation {
  const _VolatileActionContinuation({
    required this.outcome,
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleActionAttemptOutcome outcome;
  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

final class _VolatileMoveResolvedResult {
  const _VolatileMoveResolvedResult({
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

final class _FieldMoveResolvedResult {
  const _FieldMoveResolvedResult({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _FieldEndOfTurnResult {
  const _FieldEndOfTurnResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _WeatherResidualResult {
  const _WeatherResidualResult({
    required this.player,
    required this.enemy,
    required this.field,
    required this.fieldEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

final class _SandstormResidualResult {
  const _SandstormResidualResult({
    required this.combatant,
    required this.fieldEvents,
  });

  final BattleCombatant combatant;
  final List<BattleFieldEvent> fieldEvents;
}

final class _FieldProgressionResult {
  const _FieldProgressionResult({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

```

### `packages/map_battle/lib/src/battle_session.dart`

```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

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
      return _applyForcedPlayerReplacement(choice as PlayerBattleChoiceSwitch);
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
      );
    }

    // Phase 1: Convertir le choix en action
    final playerAction = forcedPlayerAction ?? _choiceToAction(choice);

    // Phase 2: Déterminer l'action de l'ennemi (IA simple)
    final enemyAction = _resolveForcedAction(
          combatantLabel: 'enemy',
          combatant: state.enemy,
        ) ??
        _chooseEnemyAction();

    // Phase 3: Résoudre le tour.
    //
    // BE3 corrige ici une ancienne approximation mensongère :
    // - on ne résout plus "joueur puis ennemi quoi qu'il arrive" ;
    // - on calcule un ordre minimal honnête une seule fois au début du tour ;
    // - priorité d'abord, puis vitesse effective, puis tie-break déterministe ;
    // - aucun recalcul rétroactif si un move modifie la vitesse pendant ce tour.
    //
    // Frontière volontairement stricte :
    // - pas de queue générique façon Showdown ;
    // - pas de PRNG ;
    // - pas de système générique de switch / hooks / réserves façon Showdown ;
    // - BE10 ajoute seulement le plus petit switch singles nécessaire :
    //   actif + réserve, switch volontaire joueur, remplacement après K.O. ;
    // - BE7 ajoute seulement un résiduel de fin de tour local pour les
    //   statuts majeurs supportés ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce
    //   tour et leur clôture immédiate.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final postTurnSwitches = _resolvePostTurnSwitchState(
      playerSide: resolvedTurn.playerSide,
      enemySide: resolvedTurn.enemySide,
    );
    final switchEvents = <BattleSwitchEvent>[
      ...resolvedTurn.turnResult.switchEvents,
      ...postTurnSwitches.switchEvents,
    ];
    final timeline = <BattleTurnEvent>[
      ...resolvedTurn.turnResult.timeline,
      ...postTurnSwitches.timeline,
    ];
    final turnResult = BattleTurnResult(
      playerAction: resolvedTurn.turnResult.playerAction,
      enemyAction: resolvedTurn.turnResult.enemyAction,
      executions: resolvedTurn.turnResult.executions,
      statusEvents: resolvedTurn.turnResult.statusEvents,
      volatileEvents: resolvedTurn.turnResult.volatileEvents,
      fieldEvents: resolvedTurn.turnResult.fieldEvents,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(timeline),
    );

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      postTurnSwitches.playerSide,
      postTurnSwitches.enemySide,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: postTurnSwitches.playerSide,
      enemySide: postTurnSwitches.enemySide,
      field: resolvedTurn.field,
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
      rng: resolvedTurn.rng,
    );
  }

  BattleSession _applyForcedPlayerReplacement(PlayerBattleChoiceSwitch choice) {
    final replacement = _resolveSwitchAction(
      side: state.playerSide,
      reserveIndex: choice.reserveIndex,
      wasForced: true,
    );

    return BattleSession._(
      state: BattleState(
        phase: BattlePhase.playerChoice,
        playerSide: replacement.side,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          switchEvents: <BattleSwitchEvent>[replacement.event],
          timeline: <BattleTurnEvent>[
            BattleTurnSwitchEvent(replacement.event),
          ],
        ),
        outcome: null,
      ),
      setup: setup,
      rng: rng,
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

  _ResolvedPostTurnSwitchState _resolvePostTurnSwitchState({
    required BattleSideState playerSide,
    required BattleSideState enemySide,
  }) {
    var updatedPlayerSide = playerSide;
    var updatedEnemySide = enemySide;
    final switchEvents = <BattleSwitchEvent>[];
    final timeline = <BattleTurnEvent>[];

    final enemyReplacementIndex =
        _firstUsableReserveIndex(updatedEnemySide.reserve);
    if (updatedEnemySide.active.isFainted && enemyReplacementIndex != null) {
      final replacement = _resolveSwitchAction(
        side: updatedEnemySide,
        reserveIndex: enemyReplacementIndex,
        wasForced: true,
      );
      updatedEnemySide = replacement.side;
      switchEvents.add(replacement.event);
      timeline.add(BattleTurnSwitchEvent(replacement.event));
    }

    if (updatedPlayerSide.active.isFainted &&
        !updatedEnemySide.active.isFainted &&
        _firstUsableReserveIndex(updatedPlayerSide.reserve) != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        side: BattleSideId.player,
        fromSpeciesId: updatedPlayerSide.active.speciesId,
      );
      switchEvents.add(replacementRequiredEvent);
      timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    return _ResolvedPostTurnSwitchState(
      playerSide: updatedPlayerSide,
      enemySide: updatedEnemySide,
      switchEvents: List<BattleSwitchEvent>.unmodifiable(switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(timeline),
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

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // IA simple : toujours utiliser la première attaque encore utilisable.
    //
    // BE4 ne réintroduit pas un comportement mensonger "le move part quand
    // même sans PP" et n'ouvre pas non plus Struggle :
    // - si aucun move n'a de PP, on échoue explicitement ;
    // - cela garde la dette visible au lieu de la maquiller.
    if (state.enemy.moves.isNotEmpty && !state.enemy.isFainted) {
      for (var i = 0; i < state.enemy.moves.length; i++) {
        if (state.enemy.moves[i].hasUsablePp) {
          return BattleActionFight(
            state.enemy.moves[i],
            moveIndex: i,
          );
        }
      }
      throw StateError(
        'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
      );
    }
    // Si aucune attaque, ne rien faire (cas edge)
    return const BattleActionRun();
  }

  /// Résout un tour de combat.
  ///
  /// [playerAction] - L'action du joueur.
  /// [enemyAction] - L'action de l'ennemi.
  ///
  /// Retourne l'état résolu du tour :
  /// - les exécutions à afficher ;
  /// - l'état joueur après dégâts / boosts ;
  /// - l'état ennemi après dégâts / boosts.
  ///
  /// Ordre de résolution BE3 :
  /// 1. on capture l'ordre une seule fois au début du tour ;
  /// 2. pour deux `Fight`, on compare :
  ///    - priorité décroissante ;
  ///    - vitesse effective décroissante ;
  ///    - tie-break déterministe explicite : joueur avant ennemi ;
  /// 3. une action de vitesse du premier acteur n'altère donc jamais
  ///    rétroactivement l'ordre du même tour ;
  /// 4. `Run`/`Capture` restent hors pseudo-queue générique ;
  /// 5. BE7 ajoute ensuite seulement une petite phase de résiduel de fin de
  ///    tour pour les statuts majeurs supportés, sans ouvrir un système de
  ///    hooks générique.
  ///
  /// Cette méthode est interne au moteur de combat.
  _ResolvedBattleTurn _resolveTurn(
      BattleAction playerAction, BattleAction enemyAction) {
    final executions = <BattleMoveExecution>[];
    final statusEvents = <BattleStatusEvent>[];
    final volatileEvents = <BattleVolatileEvent>[];
    final fieldEvents = <BattleFieldEvent>[];
    final switchEvents = <BattleSwitchEvent>[];
    final timeline = <BattleTurnEvent>[];
    var player = state.player;
    var playerReserve = state.playerReserve;
    var enemy = state.enemy;
    var enemyReserve = state.enemyReserve;
    var field = state.field;
    var turnRng = rng;
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
    );

    for (final orderedAction in orderedActions) {
      switch (orderedAction.actor) {
        case _BattleActor.player:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'player',
              move: move,
              moveIndex: moveIndex,
              attacker: player,
              defender: enemy,
              field: field,
              targetLabel: 'enemy',
              rng: turnRng,
            );
            player = resolution.attacker;
            enemy = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
            timeline.addAll(resolution.timeline);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              side: BattleSideState.player(
                active: player,
                reserve: playerReserve,
              ),
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            player = resolution.side.active;
            playerReserve = resolution.side.reserve;
            switchEvents.add(resolution.event);
            timeline.add(BattleTurnSwitchEvent(resolution.event));
          } else if (orderedAction.action is BattleActionRecharge) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _conditionEngine.runForcedContinueTurn(
              combatantLabel: 'player',
              combatant: player,
            );
            player = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
            timeline.addAll(_turnEventsFromVolatile(resolution.volatileEvents));
          }
        case _BattleActor.enemy:
          if (orderedAction.action
              case BattleActionFight(:final move, :final moveIndex)) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveMoveExecution(
              attackerLabel: 'enemy',
              move: move,
              moveIndex: moveIndex,
              attacker: enemy,
              defender: player,
              field: field,
              targetLabel: 'player',
              rng: turnRng,
            );
            enemy = resolution.attacker;
            player = resolution.defender;
            field = resolution.field;
            turnRng = resolution.rng;
            if (resolution.execution != null) {
              executions.add(resolution.execution!);
            }
            statusEvents.addAll(resolution.statusEvents);
            volatileEvents.addAll(resolution.volatileEvents);
            fieldEvents.addAll(resolution.fieldEvents);
            timeline.addAll(resolution.timeline);
          } else if (orderedAction.action
              case BattleActionSwitch(:final reserveIndex)) {
            final resolution = _resolveSwitchAction(
              side: BattleSideState.enemy(
                active: enemy,
                reserve: enemyReserve,
              ),
              reserveIndex: reserveIndex,
              wasForced: false,
            );
            enemy = resolution.side.active;
            enemyReserve = resolution.side.reserve;
            switchEvents.add(resolution.event);
            timeline.add(BattleTurnSwitchEvent(resolution.event));
          } else if (orderedAction.action is BattleActionRecharge) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _conditionEngine.runForcedContinueTurn(
              combatantLabel: 'enemy',
              combatant: enemy,
            );
            enemy = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
            timeline.addAll(_turnEventsFromVolatile(resolution.volatileEvents));
          }
      }
    }

    final residualResolution = _conditionEngine.runEndOfTurn(
      player: player,
      enemy: enemy,
      field: field,
    );
    player = residualResolution.player;
    enemy = residualResolution.enemy;
    field = residualResolution.field;
    statusEvents.addAll(residualResolution.statusEvents);
    fieldEvents.addAll(residualResolution.fieldEvents);
    timeline.addAll(_turnEventsFromStatus(residualResolution.statusEvents));
    timeline.addAll(_turnEventsFromField(residualResolution.fieldEvents));

    return _ResolvedBattleTurn(
      playerSide: BattleSideState.player(
        active: player,
        reserve: playerReserve,
      ),
      enemySide: BattleSideState.enemy(
        active: enemy,
        reserve: enemyReserve,
      ),
      field: field,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
        statusEvents: statusEvents,
        volatileEvents: volatileEvents,
        fieldEvents: fieldEvents,
        switchEvents: switchEvents,
        timeline: timeline,
      ),
    );
  }

  List<_OrderedBattleAction> _resolveTurnOrder({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE3 refuse d'introduire une fausse queue générique.
    //
    // Le moteur actuel n'a besoin que d'un ordre honnête pour deux actions :
    // - si ce sont deux `Fight`, on compare priorité puis vitesse effective ;
    // - sinon, on conserve l'ordre historique minimal, car les autres actions
    //   restent déjà gérées explicitement ailleurs (`Run`/`Capture`) ou ne
    //   sont pas de vrais chemins gameplay du moteur MVP.
    if (!_supportsOrderedResolution(playerAction) ||
        !_supportsOrderedResolution(enemyAction)) {
      return <_OrderedBattleAction>[
        _OrderedBattleAction(
          actor: _BattleActor.player,
          action: playerAction,
        ),
        _OrderedBattleAction(
          actor: _BattleActor.enemy,
          action: enemyAction,
        ),
      ];
    }

    final playerPriority = _priorityForResolvedAction(playerAction);
    final enemyPriority = _priorityForResolvedAction(enemyAction);
    if (playerPriority != enemyPriority) {
      return playerPriority > enemyPriority
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
    final trickRoomActive = _conditionEngine.doesFieldInvertSpeedOrder(field);
    if (playerSpeed != enemySpeed) {
      final playerActsFirst =
          trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
      return playerActsFirst
          ? <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
            ]
          : <_OrderedBattleAction>[
              _OrderedBattleAction(
                actor: _BattleActor.enemy,
                action: enemyAction,
              ),
              _OrderedBattleAction(
                actor: _BattleActor.player,
                action: playerAction,
              ),
            ];
    }

    // Tie-break volontairement déterministe et documenté :
    // - pas de PRNG pour résoudre les égalités d'ordre ;
    // - BE4 introduit bien un seam RNG pour le hit pipeline, mais pas pour ce
    //   tie-break ;
    // - pas de Fischer-Yates façon Showdown ;
    // - Trick Room n'inverse pas ce tie-break : seul l'ordre de vitesse est
    //   renversé ;
    // - on choisit "joueur avant ennemi" parce que c'est stable, testable,
    //   et cohérent avec l'historique du moteur jusqu'ici.
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        actor: _BattleActor.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        actor: _BattleActor.enemy,
        action: enemyAction,
      ),
    ];
  }

  bool _supportsOrderedResolution(BattleAction action) {
    return action is BattleActionFight ||
        action is BattleActionRecharge ||
        action is BattleActionSwitch;
  }

  int _priorityForResolvedAction(BattleAction action) {
    return switch (action) {
      // Politique BE10 explicitement simplifiée :
      // - un switch volontaire singles résout avant un `Fight` standard ;
      // - on n'ouvre pas pour autant une vraie taxonomie Showdown de priorités
      //   de switch, selfSwitch, forceSwitch, etc. ;
      // - cette constante locale suffit au sous-ensemble honnête du lot.
      BattleActionSwitch() => 6,
      BattleActionFight(:final move) => move.priority,
      BattleActionRecharge() => 0,
      _ => 0,
    };
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
    required String attackerLabel,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required String targetLabel,
    required BattleRng rng,
  }) {
    final actionAttempt = _conditionEngine.runActionAttempt(
      attackerLabel: attackerLabel,
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
        attacker: attackerLabel,
        move: actionAttempt.attacker.moves[moveIndex],
        target: _resolveExecutionTargetLabel(
          move: move,
          attackerLabel: attackerLabel,
          opponentLabel: targetLabel,
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
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: actionAttempt.attacker,
      defender: defender,
    );
    preHitVolatileEvents.addAll(hitInterception.volatileEvents);

    if (hitInterception.blockedByProtect) {
      final blockedExecution = BattleMoveExecution(
        attacker: attackerLabel,
        move: hitInterception.attacker.moves[moveIndex],
        target: _resolveExecutionTargetLabel(
          move: move,
          attackerLabel: attackerLabel,
          opponentLabel: targetLabel,
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
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
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
      attacker: attackerLabel,
      move: postMoveConditions.attacker.moves[moveIndex],
      target: _resolveExecutionTargetLabel(
        move: move,
        attackerLabel: attackerLabel,
        opponentLabel: targetLabel,
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

  String _resolveExecutionTargetLabel({
    required BattleMove move,
    required String attackerLabel,
    required String opponentLabel,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerLabel,
      BattleMoveTarget.field => 'field',
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        opponentLabel,
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

enum _BattleActor {
  player,
  enemy,
}

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.actor,
    required this.action,
  });

  final _BattleActor actor;
  final BattleAction action;
}

class _ResolvedBattleTurn {
  const _ResolvedBattleTurn({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.turnResult,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
}

class _ResolvedPostTurnSwitchState {
  const _ResolvedPostTurnSwitchState({
    required this.playerSide,
    required this.enemySide,
    required this.switchEvents,
    required this.timeline,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
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

### `packages/map_battle/test/battle_condition_engine_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/battle_condition_engine.dart';
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

BattleMove _move({
  required String id,
  String? name,
  int power = 40,
  String type = 'normal',
  BattleMoveCategory category = BattleMoveCategory.physical,
  BattleMoveTarget target = BattleMoveTarget.opponent,
  BattleMoveAccuracy accuracy = const BattleMoveAccuracy.percent(value: 100),
  int pp = 10,
  int? currentPp,
  BattleMoveMajorStatusEffect? majorStatusEffect,
  BattleVolatileStatusId? selfVolatileStatus,
  bool breaksProtect = false,
  bool requiresRecharge = false,
  BattleChargeThenStrikeEffect? chargeThenStrikeEffect,
  BattleWeatherId? weatherEffect,
  BattlePseudoWeatherId? pseudoWeatherEffect,
}) {
  return BattleMove(
    id: id,
    name: name ?? id,
    power: power,
    type: type,
    category: category,
    target: target,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    majorStatusEffect: majorStatusEffect,
    selfVolatileStatus: selfVolatileStatus,
    breaksProtect: breaksProtect,
    requiresRecharge: requiresRecharge,
    chargeThenStrikeEffect: chargeThenStrikeEffect,
    weatherEffect: weatherEffect,
    pseudoWeatherEffect: pseudoWeatherEffect,
  );
}

BattleCombatant _combatant({
  required String speciesId,
  int currentHp = 100,
  int maxHp = 100,
  BattleMajorStatusState? majorStatus,
  BattleVolatileState volatileState = const BattleVolatileState(),
  BattleTypingSnapshot? typing,
  required List<BattleMove> moves,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    level: 40,
    currentHp: currentHp,
    maxHp: maxHp,
    stats: _stats(),
    majorStatus: majorStatus,
    volatileState: volatileState,
    typing: typing,
    moves: moves,
  );
}

void main() {
  group('BattleConditionEngine Phase E mini event runners', () {
    const engine = BattleConditionEngine();

    test('runActionAttempt spends PP and exposes a paralysis gate outcome', () {
      final attacker = _combatant(
        speciesId: 'locked',
        majorStatus: const BattleMajorStatusState.par(),
        moves: <BattleMove>[
          _move(
            id: 'tackle',
            currentPp: 10,
          ),
        ],
      );

      final result = engine.runActionAttempt(
        attackerLabel: 'player',
        move: attacker.moves.single,
        moveIndex: 0,
        attacker: attacker,
        rng: const BattleScriptedRng(<int>[1]),
      );

      expect(
        result.outcome,
        equals(BattleActionAttemptOutcome.preventedAction),
      );
      expect(result.attacker.moves.single.currentPp, equals(9));
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.preventedAction),
      );
      expect(result.volatileEvents, isEmpty);
    });

    test('runActionAttempt starts a charge turn honestly', () {
      final attacker = _combatant(
        speciesId: 'charger',
        moves: <BattleMove>[
          _move(
            id: 'solar_beam',
            name: 'Solar Beam',
            power: 120,
            type: 'grass',
            category: BattleMoveCategory.special,
            chargeThenStrikeEffect: const BattleChargeThenStrikeEffect(
              chargeStateId: 'solar_charge',
            ),
          ),
        ],
      );

      final result = engine.runActionAttempt(
        attackerLabel: 'player',
        move: attacker.moves.single,
        moveIndex: 0,
        attacker: attacker,
        rng: const BattleSeededRng(),
      );

      expect(
        result.outcome,
        equals(BattleActionAttemptOutcome.chargeStarted),
      );
      expect(result.attacker.moves.single.currentPp, equals(9));
      expect(result.attacker.volatileState.pendingCharge, isNotNull);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.chargeStarted),
      );
    });

    test('runHitInterception blocks an opponent move behind Protect', () {
      final attacker = _combatant(
        speciesId: 'attacker',
        moves: <BattleMove>[_move(id: 'tackle')],
      );
      final defender = _combatant(
        speciesId: 'defender',
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runHitInterception(
        move: attacker.moves.single,
        attackerLabel: 'enemy',
        targetLabel: 'player',
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isTrue);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBlocked),
      );
    });

    test('runHitInterception lets breakProtect pierce and clear Protect', () {
      final attacker = _combatant(
        speciesId: 'attacker',
        moves: <BattleMove>[
          _move(
            id: 'feint',
            breaksProtect: true,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'defender',
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runHitInterception(
        move: attacker.moves.single,
        attackerLabel: 'enemy',
        targetLabel: 'player',
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isFalse);
      expect(result.defender.volatileState.protectActive, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBroken),
      );
    });

    test('runMoveResolved applies a supported major status on hit', () {
      final attacker = _combatant(
        speciesId: 'sparkitten',
        moves: <BattleMove>[
          _move(
            id: 'ember',
            type: 'fire',
            category: BattleMoveCategory.special,
            majorStatusEffect: const BattleMoveMajorStatusEffect(
              status: BattleMajorStatusId.brn,
            ),
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerLabel: 'player',
        targetLabel: 'enemy',
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.defender.majorStatus?.id, equals(BattleMajorStatusId.brn));
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.applied),
      );
    });

    test('runMoveResolved can mark an honest recharge follow-up', () {
      final attacker = _combatant(
        speciesId: 'beammon',
        moves: <BattleMove>[
          _move(
            id: 'hyper_beam',
            name: 'Hyper Beam',
            power: 120,
            category: BattleMoveCategory.special,
            requiresRecharge: true,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerLabel: 'player',
        targetLabel: 'enemy',
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.attacker.volatileState.mustRecharge, isTrue);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.rechargeRequired),
      );
    });

    test('runMoveResolved can set a weather state through the field rules', () {
      final attacker = _combatant(
        speciesId: 'rainmon',
        moves: <BattleMove>[
          _move(
            id: 'rain_dance',
            name: 'Rain Dance',
            power: 0,
            type: 'water',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: const BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.rain,
          ),
        ],
      );
      final defender = _combatant(
        speciesId: 'dummy',
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runMoveResolved(
        move: attacker.moves.single,
        attackerLabel: 'player',
        targetLabel: 'field',
        attacker: attacker,
        defender: defender,
        field: const BattleFieldState(),
        wasImmune: false,
        rng: const BattleSeededRng(),
      );

      expect(result.field.weather?.id, equals(BattleWeatherId.rain));
      expect(result.field.weather?.remainingTurns, equals(5));
      expect(
        result.fieldEvents.single.kind,
        equals(BattleFieldEventKind.weatherSet),
      );
    });

    test('runForcedContinueTurn spends the recharge turn and clears it', () {
      final combatant = _combatant(
        speciesId: 'beammon',
        volatileState: const BattleVolatileState(
          mustRecharge: true,
        ),
        moves: <BattleMove>[_move(id: 'hyper_beam')],
      );

      final result = engine.runForcedContinueTurn(
        combatantLabel: 'player',
        combatant: combatant,
      );

      expect(result.combatant.volatileState.mustRecharge, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.rechargeTurnSpent),
      );
    });

    test(
        'runEndOfTurn applies toxic and sandstorm, expires field, and clears transient protect',
        () {
      final player = _combatant(
        speciesId: 'player',
        majorStatus: const BattleMajorStatusState.tox(toxicCounter: 2),
        volatileState: const BattleVolatileState(
          protectActive: true,
        ),
        typing: const BattleTypingSnapshot(primaryType: 'grass'),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );
      final enemy = _combatant(
        speciesId: 'enemy',
        typing: const BattleTypingSnapshot(primaryType: 'grass'),
        moves: <BattleMove>[_move(id: 'growl', power: 0)],
      );

      final result = engine.runEndOfTurn(
        player: player,
        enemy: enemy,
        field: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.sandstorm,
            remainingTurns: 1,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 1,
          ),
        ),
      );

      expect(result.player.majorStatus?.id, equals(BattleMajorStatusId.tox));
      expect(result.player.majorStatus?.toxicCounter, equals(3));
      expect(result.player.volatileState.protectActive, isFalse);
      expect(result.player.currentHp, equals(82));
      expect(result.enemy.currentHp, equals(94));
      expect(result.field.weather, isNull);
      expect(result.field.pseudoWeather, isNull);
      expect(
        result.statusEvents.single.kind,
        equals(BattleStatusEventKind.residualDamage),
      );
      expect(
        result.fieldEvents.map((event) => event.kind).toList(growable: false),
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherResidualDamage,
          BattleFieldEventKind.weatherResidualDamage,
          BattleFieldEventKind.weatherExpired,
          BattleFieldEventKind.pseudoWeatherExpired,
        ]),
      );
    });

    test(
        'resolveStatusDamageMultiplier centralizes the burn malus for physical damage',
        () {
      final attacker = _combatant(
        speciesId: 'burned',
        majorStatus: const BattleMajorStatusState.brn(),
        moves: <BattleMove>[
          _move(
            id: 'slash',
            power: 70,
            category: BattleMoveCategory.physical,
          ),
        ],
      );

      final physicalMultiplier = engine.resolveStatusDamageMultiplier(
        move: attacker.moves.single,
        attacker: attacker,
      );
      final specialMultiplier = engine.resolveStatusDamageMultiplier(
        move: _move(
          id: 'flamethrower',
          power: 90,
          type: 'fire',
          category: BattleMoveCategory.special,
        ),
        attacker: attacker,
      );

      expect(physicalMultiplier, equals(0.5));
      expect(specialMultiplier, equals(1.0));
    });

    test(
        'resolveStatusAdjustedSpeed centralizes the paralysis slow with honest clamping',
        () {
      final paralyzed = _combatant(
        speciesId: 'slowpoke',
        majorStatus: const BattleMajorStatusState.par(),
        moves: <BattleMove>[_move(id: 'tackle')],
      );

      expect(
        engine.resolveStatusAdjustedSpeed(
          combatant: paralyzed,
          stagedSpeed: 13,
        ),
        equals(6),
      );
      expect(
        engine.resolveStatusAdjustedSpeed(
          combatant: paralyzed,
          stagedSpeed: 1,
        ),
        equals(1),
      );
    });
  });
}

```

### `packages/map_battle/test/battle_volatiles_test.dart`

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

BattleSession _session({
  required BattleMoveData playerMove,
  required BattleMoveData enemyMove,
  BattleMajorStatusState? playerMajorStatus,
  BattleMajorStatusState? enemyMajorStatus,
  BattleVolatileState playerVolatileState = const BattleVolatileState(),
  BattleVolatileState enemyVolatileState = const BattleVolatileState(),
  BattleRng rng = const BattleSeededRng(),
  int playerSpeed = 70,
  int enemySpeed = 40,
  int playerHp = 80,
  int enemyHp = 80,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: BattleCombatantData(
        speciesId: 'playermon',
        level: 30,
        maxHp: playerHp,
        stats: _stats(speed: playerSpeed),
        majorStatus: playerMajorStatus,
        volatileState: playerVolatileState,
        moves: <BattleMoveData>[playerMove],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'enemymon',
        level: 30,
        maxHp: enemyHp,
        stats: _stats(speed: enemySpeed),
        majorStatus: enemyMajorStatus,
        volatileState: enemyVolatileState,
        moves: <BattleMoveData>[enemyMove],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
    rng: rng,
  );
}

void main() {
  group('BattleSession BE8 useful volatiles', () {
    test('Protect blocks a slower opposing attack after activation', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'tackle',
          name: 'Tackle',
          power: 40,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);
      final enemyExecution = afterTurn.state.currentTurn!.executions
          .where((execution) => execution.attacker == 'enemy')
          .single;

      expect(afterTurn.state.player.currentHp, equals(80));
      expect(afterTurn.state.player.volatileState.protectActive, isFalse);
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
          BattleVolatileEventKind.protectBlocked,
        ]),
      );
      expect(enemyExecution.damage, equals(0));
      expect(enemyExecution.didHit, isTrue);
    });

    test('Protect does not retroactively block a faster opposing attack', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'tackle',
          name: 'Tackle',
          power: 40,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 30,
        enemySpeed: 80,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
        ]),
      );
    });

    test('breakProtect pierces an active protection honestly', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'protect',
          name: 'Protect',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
          accuracy: BattleMoveAccuracy.alwaysHits(),
          selfVolatileStatus: BattleVolatileStatusId.protect,
        ),
        enemyMove: const BattleMoveData(
          id: 'feint',
          name: 'Feint',
          power: 30,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          breaksProtect: true,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final volatileKinds = afterTurn.state.currentTurn!.volatileEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        volatileKinds,
        equals(<BattleVolatileEventKind>[
          BattleVolatileEventKind.protectActivated,
          BattleVolatileEventKind.protectBroken,
        ]),
      );
    });

    test('breakProtect does nothing special when no protect is active', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        enemyMove: const BattleMoveData(
          id: 'feint',
          name: 'Feint',
          power: 30,
          type: 'normal',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
          breaksProtect: true,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.player.currentHp, lessThan(80));
      expect(
        afterTurn.state.currentTurn!.volatileEvents.where(
            (event) => event.kind == BattleVolatileEventKind.protectBroken),
        isEmpty,
      );
    });

    test('requireRecharge forces a visible skipped turn and then clears', () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'hyper_beam',
          name: 'Hyper Beam',
          power: 90,
          type: 'normal',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          requiresRecharge: true,
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 80,
        enemySpeed: 40,
        enemyHp: 140,
      );

      final afterAttack = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(
        afterAttack.getAvailableChoices(),
        equals(<PlayerBattleChoice>[const PlayerBattleChoiceContinue()]),
      );
      expect(
        afterAttack.state.currentTurn!.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeRequired)
            .single
            .sourceMoveId,
        equals('hyper_beam'),
      );

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn!.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
    });

    test(
        'chargeThenStrike charges first, releases next turn, and spends PP once',
        () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'solar_beam',
          name: 'Solar Beam',
          power: 120,
          type: 'grass',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          pp: 10,
          chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
            chargeStateId: 'solar_charge',
          ),
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerSpeed: 80,
        enemySpeed: 40,
      );

      final afterCharge = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterCharge.state.enemy.currentHp, equals(80));
      expect(afterCharge.state.player.moves.single.currentPp, equals(9));
      expect(afterCharge.state.player.volatileState.pendingCharge, isNotNull);
      expect(
        afterCharge.getAvailableChoices(),
        equals(<PlayerBattleChoice>[const PlayerBattleChoiceContinue()]),
      );
      expect(
        afterCharge.state.currentTurn!.volatileEvents
            .where(
                (event) => event.kind == BattleVolatileEventKind.chargeStarted)
            .single
            .chargeStateId,
        equals('solar_charge'),
      );

      final afterRelease =
          afterCharge.applyChoice(const PlayerBattleChoiceContinue());
      final playerExecution = afterRelease.state.currentTurn!.executions
          .where((execution) => execution.attacker == 'player')
          .single;

      expect(afterRelease.state.player.volatileState.pendingCharge, isNull);
      expect(afterRelease.state.player.moves.single.currentPp, equals(9));
      expect(afterRelease.state.enemy.currentHp, lessThan(80));
      expect(playerExecution.move.id, equals('solar_beam'));
      expect(playerExecution.damage, greaterThan(0));
      expect(
        afterRelease.state.currentTurn!.volatileEvents
            .where(
                (event) => event.kind == BattleVolatileEventKind.chargeReleased)
            .single
            .sourceMoveId,
        equals('solar_beam'),
      );
    });

    test(
        'paralysis on the first charge turn spends PP but does not arm a fake pending charge',
        () {
      final session = _session(
        playerMove: const BattleMoveData(
          id: 'solar_beam',
          name: 'Solar Beam',
          power: 120,
          type: 'grass',
          category: BattleMoveCategory.special,
          target: BattleMoveTarget.opponent,
          pp: 10,
          chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
            chargeStateId: 'solar_charge',
          ),
        ),
        enemyMove: const BattleMoveData(
          id: 'growl',
          name: 'Growl',
          power: 0,
          type: 'normal',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
        playerMajorStatus: const BattleMajorStatusState.par(),
        rng: const BattleScriptedRng(<int>[1]),
        playerSpeed: 80,
        enemySpeed: 40,
      );

      final afterBlocked =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterBlocked.state.player.moves.single.currentPp, equals(9));
      expect(afterBlocked.state.player.volatileState.pendingCharge, isNull);
      expect(
        afterBlocked.state.currentTurn!.statusEvents
            .where(
              (event) => event.kind == BattleStatusEventKind.preventedAction,
            )
            .single
            .status,
        equals(BattleMajorStatusId.par),
      );
      expect(
        afterBlocked.state.currentTurn!.volatileEvents.where(
          (event) => event.kind == BattleVolatileEventKind.chargeStarted,
        ),
        isEmpty,
      );
      expect(
        afterBlocked.decisionRequest,
        isA<BattleTurnChoiceRequest>(),
      );
    });
  });
}

```

## 20. État git final utile

### `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_volatiles_test.dart
?? packages/map_battle/lib/src/battle_condition_engine.dart
?? packages/map_battle/test/battle_condition_engine_test.dart
?? reports/phase-e-mini-event-condition-engine-report.md
```

### `git diff --stat`

```text
 packages/map_battle/lib/src/battle_session.dart    | 1006 ++------------------
 .../map_battle/test/battle_volatiles_test.dart     |   60 ++
 2 files changed, 143 insertions(+), 923 deletions(-)
```

Note honnête : `git diff --stat` ne compte pas les fichiers non suivis ; les nouveaux fichiers apparaissent donc dans `git status` et `git ls-files --others`, pas dans cette sortie.

### `git ls-files --others --exclude-standard`

```text
packages/map_battle/lib/src/battle_condition_engine.dart
packages/map_battle/test/battle_condition_engine_test.dart
reports/phase-e-mini-event-condition-engine-report.md
```

## 21. Checklist finale

- [x] ai-je audité le code réel avant de modifier ?
- [x] ai-je identifié les vrais event points minimaux utiles ?
- [x] ai-je évité un faux event bus générique ?
- [x] ai-je gardé `BattleSession` comme orchestrateur ?
- [x] ai-je réellement sorti une part significative de la logique conditionnelle de `battle_session.dart` ?
- [x] ai-je évité d'ouvrir Phase F/G/H en douce ?
- [x] ai-je corrigé les remarques valides de review ?
- [x] ai-je rerun analyze/tests/smoke utiles localement ?
- [x] ai-je gardé le runtime intact sauf vérification de compatibilité ?
- [x] ai-je évité toute écriture Git interdite ?
- [x] ai-je inclus le contenu complet des fichiers touchés ?
- [x] ai-je distingué le confirmé, l'inféré et l'incertain ?

## Réponse finale demandée

### Phase E est-elle réellement réussie ?
Oui. Confirmé par lecture de code et par exécution.

### Qu'est-ce qu'elle débloque exactement pour Phase F ?
- une frontière claire des moments conditionnels du tour.
- un moteur moins dépendant de branches massives dans `BattleSession`.
- un lieu unique et déjà vivant pour les règles de cycle de vie des conditions supportées.
- une base plus honnête pour discuter ensuite d'un scheduling plus riche sans tout mélanger à la logique de statut/volatile/field.

### Qu'est-ce qu'elle ne débloque PAS encore ?
- aucune vraie queue d'actions.
- aucune gestion enrichie des interruptions complexes.
- aucun système riche side/slot condition.
- aucune mécanique avancée type selfSwitch/forceSwitch/hazards.
- aucun event engine généraliste.

### Le prochain lot logique est-il bien Phase F ?
Oui, **le prochain lot logique est bien Phase F**. Je ne vois pas de problème de fond restant dans E qui impose de rouvrir E avant d'avancer. La frontière Phase E reste volontairement bornée et honnête ; ce qui manque désormais pour aller plus loin relève surtout du scheduling et des enchaînements, donc de F.
