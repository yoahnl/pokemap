# Lot 3 — BattleOpponentPolicy Seam Report

Date: 2026-04-19

## 1. Résumé exécutif honnête

Le lot 3 est réussi dans un périmètre strictement battle-core local.

Le changement retenu est volontairement petit :

- la logique de choix ennemi n'est plus codée directement dans `battle_session.dart` sous la forme de l'ancien `_chooseEnemyAction()` ;
- un seam dédié `BattleOpponentPolicy` vit maintenant dans `packages/map_battle/lib/src/battle_opponent_policy.dart` ;
- ce seam reste `fight-only`, battle-local et n'ouvre ni difficulté, ni profils `1..10`, ni scripts trainer/boss, ni switch/replacement intelligents ;
- la session garde les cas forcés, les dead-ends explicites et la légalité battle réelle ;
- la policy par défaut `BattleFirstLegalOpponentPolicy` conserve un comportement équivalent à l'existant : premier move adverse encore légal ;
- aucun wiring runtime n'a été ajouté ;
- aucune dérive vers `R4` n'a été ouverte.

Le lot prépare proprement le lot 4 en empêchant le futur routage de difficulté de revenir se recoller dans `battle_session.dart`, mais sans exposer déjà une API produit de difficulté ni un zoo de policies.

## 2. Pré-gates réellement exécutés + résultats

Commandes exactes exécutées au début du lot :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```


Résultats réellement observés lors du pré-gate initial :

- `git status --short --untracked-files=all` : aucune sortie
- `git diff --stat` : aucune sortie
- `git ls-files --others --exclude-standard` : aucune sortie

Interprétation honnête :

- malgré le contexte historique du prompt, le worktree réel visible au début de ce lot était propre ;
- je n'ai donc pas traité un bruit Git préalable comme baseline de modification ;
- j'ai néanmoins conservé une lecture prudente du repo et je n'ai rien reset ni discard.

Note d'incident outillage :

- les premières exécutions des pré-gates via l'enveloppe parallèle du terminal rendaient des sorties vides brutes difficiles à archiver ;
- j'ai donc revalidé ensuite l'état Git courant via un wrapper Python pour capturer le texte exact sans changer le fond du travail read-only.

## 3. Méthode réellement suivie

Méthode suivie :

1. relire les sources canoniques et les reports des lots précédents ;
2. relire le battle-core utile autour de `createBattleSession`, `BattleSession`, `BattleAction`, `BattleTurnResult` et des tests battle existants ;
3. chercher précisément tous les points où `_chooseEnemyAction()` ou équivalent était encore utilisé ;
4. classer le scope du lot 3 avant patch ;
5. utiliser les sub-agents demandés pour valider le plus petit seam honnête ;
6. écrire d'abord un test rouge dédié au nouveau seam ;
7. implémenter la policy minimale et la délégation depuis la session ;
8. relancer les validations `map_battle` demandées ;
9. demander une review séparée et corriger le point utile remonté ;
10. produire ce report complet.

Skills/plugins réellement utilisés :

- `Superpowers:brainstorming`
- `Superpowers:test-driven-development`
- `Superpowers:requesting-code-review`

Je n'ai pas utilisé de skill `Game Studio` au-delà de la prise en compte du plugin explicitement mentionné, parce que ce lot ne touche ni UI, ni layout runtime, ni playtest visuel.

## 4. Périmètre inclus / exclu

### Inclus

- extraction du choix fight adverse hors de `battle_session.dart`
- création d'un seam battle-local dédié
- policy par défaut explicite et équivalente au comportement existant
- garde-fous pour empêcher le seam de synthétiser une action hors contrat
- tests battle ciblés pour prouver le seam
- propagation du seam dans les copies immuables de `BattleSession`

### Exclus volontairement

- toute difficulté `1..10`
- tout profil interne de difficulté
- tout script trainer/boss
- tout switch intelligent
- tout replacement intelligent
- tout targeting riche
- tout wiring runtime
- toute modification UI/backgrounds
- toute doc canonique battle
- tout refactor battle-core plus large

## 5. Classification initiale des sujets du lot 3

- seam `BattleOpponentPolicy` ou équivalent : `required_now`
- policy par défaut explicite : `required_now`
- extraction de `_chooseEnemyAction()` : `required_now`
- scope fight-only : `required_now`
- éventuelle modification de `battle_session.dart` : `required_now`
- éventuelle modification de `map_battle.dart` : `defer_not_lot3`
- éventuelle modification de tests battle : `required_now`
- éventuel wiring runtime : `defer_not_lot3`
- difficulté `1..10` : `defer_not_lot3`
- profils internes : `defer_not_lot3`
- scripts trainer/boss : `defer_not_lot3`
- switch intelligent : `defer_not_lot3`
- replacement intelligent : `defer_not_lot3`
- garde-fou validant que la policy retourne bien une action fournie par la session : `fix_now_small`

## 6. Fichiers lus

Docs / reports :

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/combat-ui-ai-audit-and-roadmap.md`
- `reports/combat-ui-ai-implementation-roadmap.md`
- `reports/lot-1-battle-scene-ui-pass-report.md`
- `reports/lot-2-contextual-backgrounds-report.md`
- `reports/r2-scheduler-consolidation-report.md`
- `reports/r3-condition-lifecycle-consolidation-report.md`

Battle-core :

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_type_chart.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`

Tests battle pertinents :

- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_condition_engine_test.dart`
- `packages/map_battle/test/battle_stealth_rock_test.dart`
- `packages/map_battle/test/battle_spikes_test.dart`

Runtime vérité produit :

- aucun fichier runtime n'a été relu au-delà du prompt initial, parce que le lot 3 n'a finalement nécessité aucun wiring runtime.

## 7. Validations réellement relancées

Tests et validations réellement exécutés :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test test/battle_opponent_policy_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
```


Validations volontairement non relancées :

- `packages/map_runtime` : non relancé, car aucun fichier runtime n'a été touché ;
- host : non relancé, car aucun wiring runtime ou host visible n'a été touché.

## 8. Résultats réellement obtenus

### Red TDD initial

Exécution : `dart test test/battle_opponent_policy_test.dart`

Résultat : échec attendu, avant code de production, avec absence du seam demandé :

- `BattleOpponentPolicy` introuvable
- `BattleFirstLegalOpponentPolicy` introuvable
- paramètre `opponentPolicy` absent sur `createBattleSession`

Conclusion : le test rouge prouvait bien qu'on demandait un seam réellement absent, pas un comportement déjà existant.

### Green ciblé

Exécution : `dart test test/battle_opponent_policy_test.dart`

Résultat : vert après implémentation du seam.

### Validation package

- `dart analyze` : `No issues found!`
- `dart test` : `All tests passed!`

Aucun test runtime/host n'a été nécessaire parce que le lot n'a touché aucun wiring hors `map_battle`.

## 9. Décisions retenues / rejetées sujet par sujet

### Seam `BattleOpponentPolicy`

Décision retenue : oui, sous ce nom exact.

Justification :

- le nom est repo-réel et lisible ;
- il dit clairement qu'on parle du choix adverse, pas d'un framework d'IA complet ;
- il reste battle-local et fight-only.

### Policy par défaut explicite

Décision retenue : oui, `BattleFirstLegalOpponentPolicy`.

Justification :

- le comportement historique réel est "premier move légal" ;
- le nom dit la vérité au lieu de maquiller cela en "default AI" plus riche qu'en réalité ;
- aucune difficulté ni heuristique cachée n'est introduite.

### Extraction de `_chooseEnemyAction()`

Décision retenue : corrigé maintenant.

Détail :

- l'ancien `_chooseEnemyAction()` a disparu ;
- `battle_session.dart` garde désormais `_resolveEnemyAction()` et `_availableEnemyFightActions()` ;
- la session garde les cas forcés, la légalité battle et les dead-ends explicites ;
- la sélection entre actions fight légales passe par la policy.

### Scope fight-only

Décision retenue : oui, strictement.

Le seam ne gère pas :

- `Run`
- `Capture`
- `Switch`
- `replacement`
- targeting riche

### Modification de `battle_session.dart`

Décision retenue : oui, minimale et ciblée.

### Modification de `map_battle.dart`

Décision rejetée in fine.

Détail honnête :

- une première passe a envisagé d'exporter le seam publiquement ;
- le reviewer a pointé que c'était une ouverture d'API plus large que nécessaire pour ce lot ;
- j'ai retiré cette exportation pour garder le seam battle-local tant que le runtime ne l'utilise pas explicitement.

### Modification de tests battle

Décision retenue : oui, un seul nouveau fichier de test ciblé.

### Wiring runtime

Décision rejetée.

Justification :

- le lot 3 n'exige pas encore de routing produit vers une policy spécifique ;
- une injection optionnelle sur `createBattleSession` suffit pour préparer le lot 4 ;
- toucher le runtime maintenant aurait été une dérive.

### Difficulté `1..10`

Décision rejetée pour ce lot.

### Profils internes

Décision rejetée pour ce lot.

### Scripts trainer/boss

Décision rejetée pour ce lot.

### Switch intelligent

Décision rejetée pour ce lot.

### Replacement intelligent

Décision rejetée pour ce lot.

### Garde-fou sur l'action retournée

Décision retenue : oui.

Justification :

- la session transmet une liste d'actions fight déjà légales ;
- la policy doit retourner l'une de ces actions, pas une nouvelle ;
- ce garde-fou empêche le seam de glisser vers un mini-moteur de génération d'actions.

## 10. Justification des fichiers modifiés

### `packages/map_battle/lib/src/battle_session.dart`

Modifié pour :

- accepter et porter la policy adverse dans la session immutable ;
- déléguer le choix fight adverse au seam dédié ;
- garder dans la session les cas forcés et les dead-ends explicites ;
- empêcher toute action retournée hors du contrat fourni.

### `packages/map_battle/lib/src/battle_session_scheduler.dart`

Modifié uniquement pour :

- propager `opponentPolicy` dans les nouvelles instances de `BattleSession` créées par le scheduler ;
- ne pas perdre ce seam pendant un remplacement forcé ou une reprise de tour.

### `packages/map_battle/lib/src/battle_opponent_policy.dart`

Créé pour :

- porter le seam battle-local minimal ;
- définir la policy par défaut explicite ;
- documenter clairement les garde-fous de périmètre.

### `packages/map_battle/test/battle_opponent_policy_test.dart`

Créé pour :

- prouver le seam en TDD ;
- verrouiller l'injection d'une policy custom ;
- vérifier que la policy ne choisit que parmi des actions fight déjà légales.

## 11. Justification des fichiers volontairement non touchés

- `packages/map_battle/lib/src/battle_session_scheduler.dart` n'a pas été refactoré au-delà du strict transport de la policy ;
- `packages/map_battle/lib/src/battle_decision.dart` non touché : le lot n'ouvre aucune request nouvelle ;
- `packages/map_battle/lib/src/battle_queue.dart` non touché : le lot ne touche pas la queue ;
- `packages/map_battle/lib/src/battle_resolution.dart` non touché : le lot ne touche pas la restitution observable ;
- `packages/map_runtime/**` non touché : aucun wiring runtime nécessaire ;
- host non touché : aucune responsabilité produit/présentation concernée ;
- docs canoniques non touchées : ce lot UI+AI parallèle n'avait pas besoin de réécrire la vérité battle canonique R3.

## 12. Description précise du seam retenu

Seam retenu :

- fichier : `packages/map_battle/lib/src/battle_opponent_policy.dart`
- contrat :

```dart
abstract interface class BattleOpponentPolicy {
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  });
}
```


Caractéristiques structurelles :

- battle-local : il vit dans `map_battle` ;
- fight-only : il ne voit que des `BattleActionFight` légales ;
- sans session entière : aucune `BattleSession` entière n'est passée ;
- sans queue ni scheduler : la policy ne planifie rien ;
- sans requests : la policy ne décide pas quel type d'action est autorisé ;
- sans runtime : aucune dépendance produit/runtime.

Répartition des responsabilités :

- `BattleSession` décide ce qui est légal et gère les dead-ends ;
- `BattleOpponentPolicy` choisit une action fight parmi les options déjà légales ;
- le scheduler reste inchangé sur son rôle d'exécution.

## 13. Description précise de la policy par défaut

Policy par défaut : `BattleFirstLegalOpponentPolicy`

Comportement :

- si la liste transmise est vide : `StateError` explicite ;
- sinon : retourne le premier élément.

Pourquoi cette forme :

- elle colle à la vérité du comportement historique ;
- elle ne prétend pas être une IA meilleure qu'avant ;
- elle laisse le lot 4 brancher plus tard d'autres policies sans redéplacer le seam.

Ce que la policy par défaut ne fait pas volontairement :

- aucune pondération de moves ;
- aucune lecture de type/puissance/statut pour décider ;
- aucun switch ;
- aucune gestion de remplacement ;
- aucune difficulté ;
- aucun aléatoire.

## 14. Ce qui reste volontairement pour le lot 4

Reste explicitement hors lot 3 :

- exposer une difficulté produit `1..10` ;
- mapper cette difficulté vers quelques profils internes ;
- router cette difficulté depuis le runtime / trainer data ;
- décider si le runtime doit passer explicitement une policy non par défaut ;
- toute éventuelle ouverture de contexte de choix plus riche si le lot 4 la justifie vraiment ;
- tout switch/replacement intelligent.

Point important :

- le lot 4 devient plus facile parce qu'il peut désormais changer **qui choisit** sans recoller cette logique dans `battle_session.dart` ;
- mais il n'hérite pas d'un framework générique déjà surdimensionné.

## 15. Incidents rencontrés

- les pré-gates exacts initiaux rendaient des sorties vides, ce qui a nécessité un second relevé diagnostique plus tard pour l'archivage textuel ;
- mon premier test rouge demandait un contexte de policy un peu trop riche ; je l'ai resserré avant implémentation après retour battle-core/subagents, pour garder un seam uniquement centré sur les actions fight légales ;
- une première passe avait aussi exporté le seam via `map_battle.dart` ; le reviewer a justement signalé que cette ouverture publique était plus large que nécessaire pour ce lot, et je l'ai retirée.

## 16. Retour des sub-agents

### Battle-core / seam design

Retour utile :

- la session doit garder les cas forcés, la légalité battle et les erreurs explicites ;
- la policy doit seulement choisir parmi des actions fight déjà légales ;
- l'injection optionnelle au niveau de `createBattleSession` est saine ;
- `BattleSetup` ne doit pas porter de comportement.

### Testing / non-régression

Retour utile :

- le meilleur observable du seam est `BattleTurnResult.enemyAction` ;
- un test doit prouver qu'une policy injectée est réellement consultée ;
- les anciens tests `no move` / `zero PP` suffisent déjà à verrouiller les dead-ends R1 si on ne change pas leur sémantique.

### Produit / anti-dérive

Retour utile :

- lot 3 = ennemi fight-only ;
- tout ce qui touche switch/replacement/targeting est déjà lot 4 / `R4` ;
- le seam serait trop gros s'il recevait la session entière ou la queue ;
- il serait trop pauvre si la vraie sélection restait encore inline dans `battle_session.dart`.

## 17. Retour du reviewer séparé

Review séparée réellement tentée : oui.

Résultat exploitable obtenu :

- un reviewer a signalé que l'export de la policy via `map_battle.dart` élargissait inutilement l'API publique pour ce lot, puisque le comportement par défaut reste déjà injecté implicitement via `createBattleSession()` ;
- j'ai appliqué cette correction en retirant l'export public.

Autre review :

- une seconde demande de review séparée a été tentée mais n'a pas renvoyé de résultat exploitable avant timeout.

État final après review :

- pas de finding bloquant restant connu ;
- un point de resserrage d'API a bien été pris en compte.

## 18. Critique explicite du prompt lui-même

### Parties utiles

- la contrainte de périmètre était très utile ;
- l'insistance sur `fight-only` a évité un faux seam trop riche ;
- le rappel constant d'éviter difficulté/switch/replacement a été bon ;
- l'exigence d'une review séparée a été utile pour détecter la sur-ouverture d'API publique.

### Parties discutables

- le prompt présupposait assez fortement que le repo serait probablement déjà dirty à cause des lots 1/2 ; en réalité, le worktree visible au début était propre ;
- le passage sur la policy recevant "probablement" certaines choses était utile comme garde-fou, mais un peu trop suggestif pour un lot qui gagnait justement à être plus petit encore.

### Parties trop rigides

- exiger le contenu complet de tous les fichiers touchés dans le report est très coûteux en taille et en maintenance ; je l'ai fait, mais c'est une contrainte lourde ;
- demander des sub-agents + reviewer dans un lot aussi petit peut être surdimensionné en coût opératoire, même si cela a quand même produit une correction utile ici.

### Ce que j'ai volontairement resserré

- j'ai refusé le premier design qui transportait un contexte plus riche vers la policy ;
- j'ai refusé l'export public du seam malgré une première tentative ;
- j'ai refusé tout wiring runtime ;
- j'ai refusé toute préparation de profils multiples ou de registry.

Pourquoi :

- parce que le plus petit seam honnête ici est simplement : "la session détermine les actions fight légales, la policy en choisit une".

## 19. Autocritique finale

Points forts :

- le seam est réellement plus petit que ma première intuition ;
- la responsabilité IA a bien quitté le cœur de `battle_session.dart` ;
- le comportement par défaut reste simple et stable ;
- aucune dérive runtime ou lot 4 n'a été ouverte.

Réserve honnête :

- ce seam est volontairement très étroit ; si le lot 4 veut plus tard des heuristiques basées sur l'adversaire, le champ ou des tags produit, il faudra peut-être élargir le contrat. Je considère quand même que c'est le bon choix ici, parce qu'anticiper ce besoin maintenant aurait surconçu le lot 3.

## 20. État git final utile

État final réellement observé après création de ce report :

### `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
?? packages/map_battle/lib/src/battle_opponent_policy.dart
?? packages/map_battle/test/battle_opponent_policy_test.dart
?? reports/lot-3-battle-opponent-policy-seam-report.md
```


### `git diff --stat`

```text
 packages/map_battle/lib/src/battle_session.dart    | 112 +++++++++++++++------
 .../lib/src/battle_session_scheduler.dart          |   2 +
 2 files changed, 86 insertions(+), 28 deletions(-)
```


### `git ls-files --others --exclude-standard`

```text
packages/map_battle/lib/src/battle_opponent_policy.dart
packages/map_battle/test/battle_opponent_policy_test.dart
reports/lot-3-battle-opponent-policy-seam-report.md
```


Interprétation :

- le lot 3 modifie exactement deux fichiers battle suivis ;
- il ajoute exactement deux nouveaux fichiers battle ;
- ce report lui-même est un nouveau fichier non tracké, ce qui est attendu ;
- aucun fichier runtime, host, asset ou doc canonique n'a été modifié.

## 21. Checklist finale

- [x] ai-je gardé le périmètre dans le lot 3 et pas au-delà ?
- [x] ai-je réellement sorti la logique IA de `battle_session.dart` ?
- [x] ai-je gardé le scope fight-only ?
- [x] ai-je évité la difficulté ?
- [x] ai-je évité les profils `1..10` ?
- [x] ai-je évité switch/replacement intelligents ?
- [x] ai-je gardé le seam battle-local ?
- [x] ai-je évité un faux framework IA ?
- [x] ai-je relancé les validations utiles ?
- [x] ai-je utilisé des sub-agents ?
- [x] ai-je fait une review séparée ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés ?
- [x] ai-je évité toute écriture Git interdite ?

## 22. Décision finale nette

- lot 3 réussi ou non : **oui**
- `battle_session.dart` réellement allégé sur la responsabilité IA ou non : **oui**
- préparation saine du lot 4 ou non : **oui**

Verdict synthétique :

- la logique de choix ennemi n'est plus codée directement dans `battle_session.dart` ;
- le seam retenu est petit, fight-only et battle-local ;
- le comportement par défaut reste stable ;
- le lot 4 pourra maintenant brancher des policies différentes sans retransformer la session en point d'absorption IA.

## 23. Contenu complet de tous les fichiers touchés

Note sur la récursion :

- ce report n'inclut pas sa propre recopie intégrale, pour éviter une récursion absurde ;
- tous les autres fichiers touchés sont reproduits intégralement ci-dessous.

### `packages/map_battle/lib/src/battle_session.dart`

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
  /// Ce seam reste volontairement petit dans le lot 3 :
  /// - la session continue à porter l'orchestration du tour, les actions
  ///   forcées et les dead-ends explicites ;
  /// - la policy ne choisit qu'entre des `BattleActionFight` déjà légales ;
  /// - la difficulté, les profils 1..10, les scripts trainer/boss et tout ce
  ///   qui touche switch/replacement/targeting restent volontairement hors
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

    // Garde-fou de périmètre lot 3 :
    // - la policy reçoit uniquement des actions fight déjà légales ;
    // - elle doit en retourner une parmi cette liste, sans en synthétiser une
    //   nouvelle ni rouvrir switch/replacement/targeting ;
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


### `packages/map_battle/lib/src/battle_session_scheduler.dart`

```dart
part of 'battle_session.dart';

/// Seams scheduler locaux consolidés en R2.
///
/// Ce fichier ne cherche pas à créer un framework battle générique :
/// - il reste privé à `battle_session.dart` via `part`;
/// - il ne publie aucun nouveau contrat runtime ou UI ;
/// - il se contente de rendre explicites les quatre niveaux déjà vivants
///   localement : action choisie, planification, consommation de queue,
///   suspension/reprise.
///
/// Ce qui reste volontairement hors de ce fichier :
/// - la frontière request/choice publique ;
/// - la sélection d'action adverse ;
/// - la résolution métier des moves, conditions et entry hazards ;
/// - toute ouverture vers R3/R4/H3.

BattleSession _applyForcedPlayerReplacement({
  required BattleSession session,
  required PlayerBattleChoiceSwitch choice,
}) {
  // R2 fait passer ce cas par le même seam scheduler que le reste sans mentir
  // sur sa nature :
  // - il s'agit bien d'une petite étape inter-tour ;
  // - il ne faut donc ni lui inventer une fin de tour, ni lui rattacher des
  //   checks post-résolution qui appartiennent au vrai tour d'origine.
  final replacementAction =
      BattleActionSwitch(reserveIndex: choice.reserveIndex);
  final turnPlan = _planForcedReplacementTurn(
    replacementAction: replacementAction,
  );
  final turn = _QueuedTurnContext(
    playerSide: session.state.playerSide,
    enemySide: session.state.enemySide,
    field: session.state.field,
    rng: session.rng,
    originalPlayerAction: turnPlan.reportedPlayerAction,
    originalEnemyAction: turnPlan.reportedEnemyAction,
  );
  _consumeTurnPlan(
    session: session,
    plan: turnPlan,
    turn: turn,
  );
  _recordFollowUpPlayerReplacementIfNeeded(
    session: session,
    turn: turn,
  );

  final outcome = session._determineOutcome(
    turn.playerSide,
    turn.enemySide,
    turn.field,
  );

  return BattleSession._(
    state: BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      currentTurn: _buildTurnResultFromContext(
        turn: turn,
        playerAction: turnPlan.reportedPlayerAction,
        enemyAction: turnPlan.reportedEnemyAction,
      ),
      outcome: outcome,
    ),
    setup: session.setup,
    rng: turn.rng,
    opponentPolicy: session.opponentPolicy,
    pendingTurn: null,
  );
}

BattleSession _resumePendingTurnWithReplacement({
  required BattleSession session,
  required PlayerBattleChoiceSwitch choice,
}) {
  final pending = session.pendingTurn;
  if (pending == null) {
    throw StateError(
      'Aucune continuation de tour n’est disponible pour reprendre un remplacement joueur.',
    );
  }

  // Le tour logique rapporté au runtime reste celui qui a déjà commencé :
  // - `reportedPlayerAction` / `reportedEnemyAction` restent donc les actions
  //   originales du tour suspendu ;
  // - la nouvelle étape de switch forcé ne vit que dans le plan de queue ;
  // - cela évite de réécrire l'histoire observable du tour au moment de la
  //   reprise.
  final turnPlan = _planPendingTurnResumption(
    pending: pending,
    replacementAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
  );
  final turn = _QueuedTurnContext.resume(pending);
  _consumeTurnPlan(
    session: session,
    plan: turnPlan,
    turn: turn,
  );

  final outcome = turn.pendingTurn != null
      ? null
      : session._determineOutcome(
          turn.playerSide,
          turn.enemySide,
          turn.field,
        );

  return BattleSession._(
    state: BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      currentTurn: _buildTurnResultFromContext(
        turn: turn,
        playerAction: turnPlan.reportedPlayerAction,
        enemyAction: turnPlan.reportedEnemyAction,
      ),
      outcome: outcome,
    ),
    setup: session.setup,
    rng: turn.rng,
    opponentPolicy: session.opponentPolicy,
    pendingTurn: turn.pendingTurn,
  );
}

/// Plan local d'un tour ou d'une étape de reprise déjà réellement supportée.
///
/// Le point important de R2 est ici :
/// - `reported*Action` décrit ce que `BattleTurnResult` devra raconter ;
/// - `initialSteps` décrit ce que la queue doit réellement exécuter ;
/// - ces deux axes coïncident pour un tour normal ;
/// - ils divergent volontairement lors d'une reprise après remplacement forcé,
///   où le switch de reprise n'est qu'une étape de queue et non la nouvelle
///   "vraie action choisie" du tour suspendu.
final class _BattleTurnPlan {
  const _BattleTurnPlan({
    required this.reportedPlayerAction,
    required this.reportedEnemyAction,
    required this.initialSteps,
    required this.allowTurnTailInsertion,
  });

  final BattleAction reportedPlayerAction;
  final BattleAction reportedEnemyAction;
  final List<BattleQueueStep> initialSteps;

  /// Indique si l'exécution de ce plan doit insérer la fin de tour canonique
  /// quand la phase d'actions se vide.
  ///
  /// R2 garde ce booléen volontairement local au seam scheduler :
  /// - un vrai tour complet l'active ;
  /// - une simple étape inter-tour de remplacement ne l'active pas ;
  /// - on évite ainsi de transformer la queue en mini-framework de phases.
  final bool allowTurnTailInsertion;
}

_BattleTurnPlan _planInitialTurn({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: playerAction,
    reportedEnemyAction: enemyAction,
    initialSteps: List<BattleQueueStep>.unmodifiable(
      _buildInitialTurnQueue(
        session: session,
        playerAction: playerAction,
        enemyAction: enemyAction,
        player: player,
        enemy: enemy,
        field: field,
      ),
    ),
    allowTurnTailInsertion: true,
  );
}

_BattleTurnPlan _planForcedReplacementTurn({
  required BattleActionSwitch replacementAction,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: replacementAction,
    reportedEnemyAction: const BattleActionNone(),
    initialSteps: List<BattleQueueStep>.unmodifiable(<BattleQueueStep>[
      BattleQueueActionStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        action: replacementAction,
        wasForced: true,
      ),
    ]),
    allowTurnTailInsertion: false,
  );
}

_BattleTurnPlan _planPendingTurnResumption({
  required _PendingTurnContinuation pending,
  required BattleActionSwitch replacementAction,
}) {
  return _BattleTurnPlan(
    reportedPlayerAction: pending.playerAction,
    reportedEnemyAction: pending.enemyAction,
    initialSteps: List<BattleQueueStep>.unmodifiable(<BattleQueueStep>[
      BattleQueueActionStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        action: replacementAction,
        wasForced: true,
      ),
      ...pending.remainingSteps,
    ]),
    allowTurnTailInsertion: true,
  );
}

void _consumeTurnPlan({
  required BattleSession session,
  required _BattleTurnPlan plan,
  required _QueuedTurnContext turn,
}) {
  // R2 garde un seul moteur de consommation :
  // - même boucle pour un vrai tour, un remplacement inter-tour et une reprise ;
  // - seules changent les étapes initiales et le droit d'insérer un turn tail ;
  // - cela clarifie la responsabilité scheduler sans ouvrir de méta-système.
  final queue = BattleTurnQueue(plan.initialSteps);

  while (!queue.isEmpty) {
    final step = queue.takeNext();
    _executeQueueStep(
      session: session,
      queue: queue,
      turn: turn,
      step: step,
    );
    if (turn.pendingTurn != null) {
      break;
    }
    if (plan.allowTurnTailInsertion) {
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }
  }
}

BattleTurnResult _buildTurnResultFromContext({
  required _QueuedTurnContext turn,
  required BattleAction playerAction,
  required BattleAction enemyAction,
}) {
  return BattleTurnResult(
    playerAction: playerAction,
    enemyAction: enemyAction,
    executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
    statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
    volatileEvents: List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
    fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
    stealthRockEvents:
        List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
    spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
    switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
    timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
  );
}

List<BattleQueueStep> _buildInitialTurnQueue({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  final orderedActions = _resolveTurnOrder(
    session: session,
    playerAction: playerAction,
    enemyAction: enemyAction,
    player: player,
    enemy: enemy,
    field: field,
  );

  return <BattleQueueStep>[
    for (final orderedAction in orderedActions)
      if (isBattleQueueManagedAction(orderedAction.action))
        BattleQueueActionStep(
          side: orderedAction.side,
          slot: BattleSlotRef.active(orderedAction.side),
          action: orderedAction.action,
          wasForced: false,
        ),
  ];
}

void _appendTurnTailWhenActionPhaseDrains({
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  if (turn.turnTailScheduled || !queue.isEmpty) {
    return;
  }

  // Le "turn tail" reste volontairement minuscule et concret :
  // - fin de tour ;
  // - checks post-résolution ;
  // - rien d'autre.
  // R2 clarifie surtout le point exact où il s'insère, sans ouvrir de nouvelle
  // taxonomie de phases.
  queue.pushBack(const BattleQueueEndOfTurnStep());
  queue.pushBack(const BattleQueuePostTurnChecksStep());
  turn.turnTailScheduled = true;
}

void _executeQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueStep step,
}) {
  switch (step) {
    case BattleQueueActionStep():
      _executeActionQueueStep(
        session: session,
        queue: queue,
        turn: turn,
        step: step,
      );
    case BattleQueueEndOfTurnStep():
      _executeEndOfTurnQueueStep(
        session: session,
        turn: turn,
      );
    case BattleQueuePostTurnChecksStep():
      _executePostTurnChecksQueueStep(
        session: session,
        queue: queue,
        turn: turn,
      );
    case BattleQueueAutoSwitchStep():
      _executeAutoSwitchQueueStep(
        session: session,
        queue: queue,
        turn: turn,
        step: step,
      );
    case BattleQueueReplacementRequiredStep():
      _executeReplacementRequiredQueueStep(
        turn: turn,
        step: step,
      );
  }
}

void _executeActionQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueActionStep step,
}) {
  final actingSide = turn.side(step.side);
  final opposingSide = turn.side(_opposingSideId(step.side));

  if (step.action case BattleActionFight(:final move, :final moveIndex)) {
    if (actingSide.active.isFainted || opposingSide.active.isFainted) {
      return;
    }

    final resolution = session._resolveMoveExecution(
      attackerSlot: actingSide.activeSlotRef,
      move: move,
      moveIndex: moveIndex,
      attacker: actingSide.active,
      defender: opposingSide.active,
      field: turn.field,
      targetSlot: opposingSide.activeSlotRef,
      rng: turn.rng,
    );
    turn.updateActive(step.side, resolution.attacker);
    turn.updateActive(_opposingSideId(step.side), resolution.defender);
    turn.field = resolution.field;
    turn.rng = resolution.rng;
    if (resolution.execution != null) {
      turn.executions.add(resolution.execution!);
    }
    turn.statusEvents.addAll(resolution.statusEvents);
    turn.volatileEvents.addAll(resolution.volatileEvents);
    turn.fieldEvents.addAll(resolution.fieldEvents);
    turn.timeline.addAll(resolution.timeline);

    final sideConditionResolution = _conditionEngine.runSideConditionMoveResolved(
      move: move,
      didResolveHit: resolution.execution?.didHit == true,
      targetSide: turn.side(_opposingSideId(step.side)),
    );
    _recordSideConditionResolution(
      turn: turn,
      sideId: _opposingSideId(step.side),
      resolution: sideConditionResolution,
    );
    return;
  }

  if (step.action case BattleActionSwitch(:final reserveIndex)) {
    final resolution = session._resolveSwitchAction(
      side: actingSide,
      reserveIndex: reserveIndex,
      wasForced: step.wasForced,
    );
  turn.updateSide(step.side, resolution.side);
  turn.switchEvents.add(resolution.event);
  turn.timeline.add(BattleTurnSwitchEvent(resolution.event));

  final entryHazards = _conditionEngine.runEntryHazards(
    side: turn.side(step.side),
  );
  _recordSideConditionResolution(
    turn: turn,
    sideId: step.side,
    resolution: entryHazards,
  );

  final sideAfterEntry = turn.side(step.side);
    if (sideAfterEntry.active.isFainted &&
        step.side == BattleSideId.player &&
        session._firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
        !queue.isEmpty) {
      _suspendTurnForImmediatePlayerReplacement(
        queue: queue,
        turn: turn,
      );
    }
    return;
  }

  if (step.action is BattleActionRecharge) {
    if (actingSide.active.isFainted || opposingSide.active.isFainted) {
      return;
    }

    final resolution = _conditionEngine.runForcedContinueTurn(
      combatantSlot: actingSide.activeSlotRef,
      combatant: actingSide.active,
    );
    turn.updateActive(step.side, resolution.combatant);
    turn.volatileEvents.addAll(resolution.volatileEvents);
    turn.timeline
        .addAll(session._turnEventsFromVolatile(resolution.volatileEvents));
  }
}

void _executeEndOfTurnQueueStep({
  required BattleSession session,
  required _QueuedTurnContext turn,
}) {
  final residualResolution = _conditionEngine.runEndOfTurn(
    player: turn.playerSide.active,
    enemy: turn.enemySide.active,
    field: turn.field,
  );
  turn.updateActive(BattleSideId.player, residualResolution.player);
  turn.updateActive(BattleSideId.enemy, residualResolution.enemy);
  turn.field = residualResolution.field;
  turn.statusEvents.addAll(residualResolution.statusEvents);
  turn.fieldEvents.addAll(residualResolution.fieldEvents);
  turn.timeline
      .addAll(session._turnEventsFromStatus(residualResolution.statusEvents));
  turn.timeline
      .addAll(session._turnEventsFromField(residualResolution.fieldEvents));
}

void _executePostTurnChecksQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  final enemyReplacementIndex =
      session._firstUsableReserveIndex(turn.enemySide.reserve);
  if (turn.enemySide.active.isFainted && enemyReplacementIndex != null) {
    queue.pushBack(
      BattleQueueAutoSwitchStep(
        side: BattleSideId.enemy,
        slot: const BattleSlotRef.active(BattleSideId.enemy),
        reserveIndex: enemyReplacementIndex,
      ),
    );
  }

  if (turn.playerSide.active.isFainted &&
      !turn.enemySide.active.isFainted &&
      session._firstUsableReserveIndex(turn.playerSide.reserve) != null) {
    // Tant qu'une chaîne d'auto-switch ennemi reste possible, on refuse
    // d'annoncer le remplacement joueur trop tôt :
    // - sinon la timeline raconterait "le joueur doit remplacer" avant que
    //   l'ennemi ait fini d'entrer réellement ;
    // - en H1/H2, un premier remplaçant ennemi peut même mourir en entrant,
    //   ce qui doit rester visible avant la request joueur.
    queue.pushBack(
      BattleQueueReplacementRequiredStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        faintedSpeciesId: turn.playerSide.active.speciesId,
      ),
    );
  }
}

void _executeAutoSwitchQueueStep({
  required BattleSession session,
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
  required BattleQueueAutoSwitchStep step,
}) {
  final resolution = session._resolveSwitchAction(
    side: turn.side(step.side),
    reserveIndex: step.reserveIndex,
    wasForced: true,
  );
  turn.updateSide(step.side, resolution.side);
  turn.switchEvents.add(resolution.event);
  turn.timeline.add(BattleTurnSwitchEvent(resolution.event));

  final entryHazards = _conditionEngine.runEntryHazards(
    side: turn.side(step.side),
  );
  _recordSideConditionResolution(
    turn: turn,
    sideId: step.side,
    resolution: entryHazards,
  );

  if (turn.side(step.side).active.isFainted) {
    final nextReserveIndex =
        session._firstUsableReserveIndex(turn.side(step.side).reserve);
    if (nextReserveIndex != null) {
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: step.side,
          slot: step.slot,
          reserveIndex: nextReserveIndex,
        ),
      );
      return;
    }
  }

  if (step.side == BattleSideId.enemy &&
      turn.playerSide.active.isFainted &&
      !turn.enemySide.active.isFainted &&
      session._firstUsableReserveIndex(turn.playerSide.reserve) != null) {
    queue.pushBack(
      BattleQueueReplacementRequiredStep(
        side: BattleSideId.player,
        slot: const BattleSlotRef.active(BattleSideId.player),
        faintedSpeciesId: turn.playerSide.active.speciesId,
      ),
    );
  }
}

void _executeReplacementRequiredQueueStep({
  required _QueuedTurnContext turn,
  required BattleQueueReplacementRequiredStep step,
}) {
  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: step.side,
    fromSpeciesId: step.faintedSpeciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
}

void _recordSideConditionResolution({
  required _QueuedTurnContext turn,
  required BattleSideId sideId,
  required BattleSideConditionResolution resolution,
}) {
  // Frontière R3 volontairement nette :
  // - l'engine conditionnel résout le "comment" des side conditions ;
  // - le scheduler garde l'ordre observable dans lequel ces effets entrent
  //   réellement dans la timeline du tour ;
  // - ce helper ne ré-invente donc aucune mécanique, il enregistre seulement
  //   la sortie déjà résolue par l'engine au bon endroit de la queue.
  turn.updateSide(sideId, resolution.side);
  turn.stealthRockEvents.addAll(resolution.stealthRockEvents);
  turn.timeline.addAll(
    resolution.stealthRockEvents.map(BattleTurnStealthRockEvent.new),
  );
  turn.spikesEvents.addAll(resolution.spikesEvents);
  turn.timeline.addAll(
    resolution.spikesEvents.map(BattleTurnSpikesEvent.new),
  );
}

void _recordFollowUpPlayerReplacementIfNeeded({
  required BattleSession session,
  required _QueuedTurnContext turn,
}) {
  final followUpReplacementIndex = turn.playerSide.active.isFainted
      ? session._firstUsableReserveIndex(turn.playerSide.reserve)
      : null;
  if (followUpReplacementIndex == null) {
    return;
  }

  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: BattleSideId.player,
    fromSpeciesId: turn.playerSide.active.speciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
}

void _suspendTurnForImmediatePlayerReplacement({
  required BattleTurnQueue queue,
  required _QueuedTurnContext turn,
}) {
  // H1/H2 ont ouvert ici le plus petit vrai seam d'interruption ; R2 ne
  // l'élargit pas, il le rend seulement plus lisible :
  // - interruption uniquement pour un remplacement joueur devenu obligatoire en
  //   plein tour après un hazard d'entrée déjà réellement supporté ;
  // - aucune généralisation en scheduler d'interruptions arbitraires ;
  // - capture exacte du reste de queue afin que la reprise continue le tour
  //   logique existant au lieu d'en inventer un nouveau.
  final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
    side: BattleSideId.player,
    fromSpeciesId: turn.playerSide.active.speciesId,
  );
  turn.switchEvents.add(replacementRequiredEvent);
  turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
  turn.pendingTurn = _PendingTurnContinuation.capture(
    turn: turn,
    remainingSteps: queue.drainRemainingSteps(),
    playerAction: turn.originalPlayerAction ?? const BattleActionNone(),
    enemyAction: turn.originalEnemyAction ?? const BattleActionNone(),
  );
}

List<_OrderedBattleAction> _resolveTurnOrder({
  required BattleSession session,
  required BattleAction playerAction,
  required BattleAction enemyAction,
  required BattleCombatant player,
  required BattleCombatant enemy,
  required BattleFieldState field,
}) {
  // Le scheduler local n'a toujours besoin que d'un ordre honnête pour deux
  // actions supportées.
  if (!isBattleQueueManagedAction(playerAction) ||
      !isBattleQueueManagedAction(enemyAction)) {
    return <_OrderedBattleAction>[
      _OrderedBattleAction(
        side: BattleSideId.player,
        action: playerAction,
      ),
      _OrderedBattleAction(
        side: BattleSideId.enemy,
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
              side: BattleSideId.player,
              action: playerAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
          ]
        : <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
          ];
  }

  final playerSpeed = session._resolveEffectiveSpeed(player);
  final enemySpeed = session._resolveEffectiveSpeed(enemy);
  final trickRoomActive = _conditionEngine.doesFieldInvertSpeedOrder(field);
  if (playerSpeed != enemySpeed) {
    final playerActsFirst =
        trickRoomActive ? playerSpeed < enemySpeed : playerSpeed > enemySpeed;
    return playerActsFirst
        ? <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
          ]
        : <_OrderedBattleAction>[
            _OrderedBattleAction(
              side: BattleSideId.enemy,
              action: enemyAction,
            ),
            _OrderedBattleAction(
              side: BattleSideId.player,
              action: playerAction,
            ),
          ];
  }

  // Tie-break toujours volontairement déterministe :
  // - R2 n'ajoute pas de PRNG d'ordre ;
  // - il garde seulement cette politique locale explicite ;
  // - cela reste une dette canoniquement documentée, pas une pseudo-parité
  //   Showdown.
  return <_OrderedBattleAction>[
    _OrderedBattleAction(
      side: BattleSideId.player,
      action: playerAction,
    ),
    _OrderedBattleAction(
      side: BattleSideId.enemy,
      action: enemyAction,
    ),
  ];
}

int _priorityForResolvedAction(BattleAction action) {
  return switch (action) {
    // Politique singles locale explicitement bornée :
    // - un switch volontaire ou forcé résout avant un `Fight` standard ;
    // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
    //   des priorités de switch.
    BattleActionSwitch() => 6,
    BattleActionFight(:final move) => move.priority,
    BattleActionRecharge() => 0,
    _ => 0,
  };
}

final class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.side,
    required this.action,
  });

  final BattleSideId side;
  final BattleAction action;
}

final class _PendingTurnContinuation {
  const _PendingTurnContinuation({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    required this.playerAction,
    required this.enemyAction,
    required this.turnTailScheduled,
    required this.remainingSteps,
    required this.executions,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.stealthRockEvents,
    required this.spikesEvents,
    required this.switchEvents,
    required this.timeline,
  });

  factory _PendingTurnContinuation.capture({
    required _QueuedTurnContext turn,
    required List<BattleQueueStep> remainingSteps,
    required BattleAction playerAction,
    required BattleAction enemyAction,
  }) {
    return _PendingTurnContinuation(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      playerAction: playerAction,
      enemyAction: enemyAction,
      turnTailScheduled: turn.turnTailScheduled,
      remainingSteps: List<BattleQueueStep>.unmodifiable(remainingSteps),
      executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
      statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
      volatileEvents:
          List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
      fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
      stealthRockEvents:
          List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
      spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
      switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
      timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
    );
  }

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleAction playerAction;
  final BattleAction enemyAction;
  final bool turnTailScheduled;
  final List<BattleQueueStep> remainingSteps;
  final List<BattleMoveExecution> executions;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
  final List<BattleSwitchEvent> switchEvents;
  final List<BattleTurnEvent> timeline;
}

/// Contexte mutable strictement local à la consommation d'une queue de tour.
///
/// R2 garde ce conteneur vivant mais le sort du gros fichier principal :
/// - la session publique reste immutable ;
/// - la mutabilité de résolution reste confinée à l'exécution de queue ;
/// - l'objet sert uniquement à agréger l'état courant et les traces observables
///   pendant un plan de scheduler.
final class _QueuedTurnContext {
  _QueuedTurnContext({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
    this.originalPlayerAction,
    this.originalEnemyAction,
  });

  factory _QueuedTurnContext.resume(_PendingTurnContinuation pending) {
    return _QueuedTurnContext(
      playerSide: pending.playerSide,
      enemySide: pending.enemySide,
      field: pending.field,
      rng: pending.rng,
      originalPlayerAction: pending.playerAction,
      originalEnemyAction: pending.enemyAction,
    )
      ..turnTailScheduled = pending.turnTailScheduled
      ..executions.addAll(pending.executions)
      ..statusEvents.addAll(pending.statusEvents)
      ..volatileEvents.addAll(pending.volatileEvents)
      ..fieldEvents.addAll(pending.fieldEvents)
      ..stealthRockEvents.addAll(pending.stealthRockEvents)
      ..spikesEvents.addAll(pending.spikesEvents)
      ..switchEvents.addAll(pending.switchEvents)
      ..timeline.addAll(pending.timeline);
  }

  BattleSideState playerSide;
  BattleSideState enemySide;
  BattleFieldState field;
  BattleRng rng;
  BattleAction? originalPlayerAction;
  BattleAction? originalEnemyAction;
  bool turnTailScheduled = false;
  _PendingTurnContinuation? pendingTurn;

  final List<BattleMoveExecution> executions = <BattleMoveExecution>[];
  final List<BattleStatusEvent> statusEvents = <BattleStatusEvent>[];
  final List<BattleVolatileEvent> volatileEvents = <BattleVolatileEvent>[];
  final List<BattleFieldEvent> fieldEvents = <BattleFieldEvent>[];
  final List<BattleStealthRockEvent> stealthRockEvents =
      <BattleStealthRockEvent>[];
  final List<BattleSpikesEvent> spikesEvents = <BattleSpikesEvent>[];
  final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
  final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];

  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }

  void updateSide(BattleSideId sideId, BattleSideState sideState) {
    switch (sideId) {
      case BattleSideId.player:
        playerSide = sideState;
      case BattleSideId.enemy:
        enemySide = sideState;
    }
  }

  void updateActive(BattleSideId sideId, BattleCombatant active) {
    final existingSide = side(sideId);
    updateSide(
      sideId,
      existingSide.withActiveAndReserve(
        active: active,
        reserve: existingSide.reserve,
      ),
    );
  }
}
```


### `packages/map_battle/lib/src/battle_opponent_policy.dart`

```dart
import 'battle_action.dart';

/// Seam battle-local de choix d'action adverse.
///
/// Ce contrat existe pour une raison volontairement étroite dans le lot 3 :
/// - sortir la sélection du move adverse de `battle_session.dart` ;
/// - empêcher le futur lot difficulté de réinjecter cette logique au milieu de
///   la session ;
/// - mais sans ouvrir dès maintenant un framework d'IA, des profils multiples,
///   du switch intelligent ou du targeting riche.
///
/// Frontières non négociables de ce seam :
/// - il ne choisit qu'entre des `BattleActionFight` déjà jugées légales ;
/// - il ne reçoit ni `BattleSession`, ni queue, ni request, ni scheduler ;
/// - il ne gère ni switch, ni replacement, ni `Run`, ni `Capture` ;
/// - il ne synthétise pas une nouvelle action : il doit retourner l'une des
///   actions fight fournies.
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
}

/// Policy adverse par défaut du dépôt.
///
/// Le lot 3 garde volontairement un comportement équivalent à l'existant :
/// - aucune difficulté ;
/// - aucune heuristique de puissance, type ou statut ;
/// - aucune variabilité pseudo-aléatoire ;
/// - simplement le premier move fight encore légal.
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
}
```


### `packages/map_battle/test/battle_opponent_policy_test.dart`

```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/battle_opponent_policy.dart';
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
  BattleStatsSnapshot? stats,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    stats: stats ?? _stats(),
    moves: moves,
  );
}

final class _LastLegalFightPolicy implements BattleOpponentPolicy {
  List<BattleActionFight>? lastLegalFightActions;

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    lastLegalFightActions = legalFightActions;
    return legalFightActions.last;
  }
}

void main() {
  group('BattleOpponentPolicy seam', () {
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
  });
}
```

