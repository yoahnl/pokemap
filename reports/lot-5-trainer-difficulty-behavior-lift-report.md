# Lot 5 — Trainer Difficulty Behavior Lift (minimal, honest, bounded)

## 1. Résumé exécutif honnête

Décision finale retenue : **lot 5 réussi** sur son objectif central, avec un refus explicite et volontaire du switch adverse volontaire pour rester sain.

Ce lot implémente un vrai **replacement trainer intelligent minimal** branché sur la difficulté trainer déjà authorée, sans rouvrir la plomberie runtime et sans réinjecter la logique de difficulté dans `battle_session.dart`.

Concrètement :
- le seam `BattleOpponentPolicy` n'est plus seulement `fight-only` ; il couvre désormais aussi **le replacement adverse forcé après K.O.**, et uniquement ce cas supplémentaire ;
- le scheduler battle consomme cette décision au moment exact où l'ennemi doit auto-remplacer un Pokémon K.O. ;
- les profils faibles / moyens / élevés se ressentent maintenant aussi sur le choix du remplaçant ;
- les wild battles et les trainers sans difficulté explicite gardent un fallback historique honnête ;
- les moves offensifs à `0 PP` ne comptent plus dans le scoring de replacement, ce qui évite un faux remplaçant "menaçant" mais inutilisable ;
- aucun switch volontaire adverse, aucun targeting riche, aucun script trainer/boss, aucune simulation multi-tour n'ont été ouverts.

En pratique, le comportement retenu est :
- difficulté faible / fallback legacy : premier remplaçant légal utilisable ;
- difficulté moyenne : remplaçant avec la meilleure pression offensive brute simple ;
- difficulté haute : remplaçant offensif le plus menaçant selon une heuristique très bornée `expected power + vitesse + marge de survie immédiate`, en ignorant les moves sans PP.

## 2. État git initial

Pré-gates réellement exécutés avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

État initial réel observé :

```text
 M examples/playable_runtime_host/ios/Runner/Info.plist
 M examples/playable_runtime_host/lib/main.dart
?? examples/.DS_Store
```

`git diff --stat` initial :

```text
 examples/playable_runtime_host/ios/Runner/Info.plist |  4 ++
 examples/playable_runtime_host/lib/main.dart         | 61 ++++++++++++++--------
 2 files changed, 44 insertions(+), 21 deletions(-)
```

Conclusion honnête :
- le worktree n'était **pas propre** avant lot 5 ;
- ce bruit était hors scope battle ;
- aucun de ces fichiers n'a été supprimé, reset, revert ou touché par le lot 5.

## 3. Méthode réellement suivie

Méthode réellement suivie :
1. exécution des pré-gates git read-only ;
2. relecture des docs/reports battle canoniques utiles ;
3. audit local des seams battle/runtime pour move choice, replacement, switch et routing runtime `battleDifficulty -> BattleOpponentPolicy` ;
4. sollicitation de sub-agents ciblés battle-core / runtime / TDD ;
5. décision de périmètre : **replacement intelligent minimal oui**, **switch volontaire adverse non** ;
6. écriture de tests rouges ciblés sur :
   - le seam pur `BattleOpponentPolicy` ;
   - l'intégration scheduler d'auto-replacement trainer ;
7. implémentation minimale du seam et du scheduler ;
8. relance des tests ciblés puis de la suite `map_battle` complète ;
9. tentative de review séparée ;
10. prise en compte du finding reviewer sur les moves à `0 PP` ;
11. ajout des tests PP correspondants ;
12. relance des validations finales ;
13. rédaction de ce report ultra complet.

## 4. Périmètre inclus / exclu

### Inclus
- extension minimale de `BattleOpponentPolicy` pour le replacement adverse forcé ;
- consommation de cette décision dans le scheduler battle ;
- tests purs et d'intégration du replacement faible / moyen / élevé ;
- preuve que les moves offensifs à `0 PP` ne trompent plus le scoring ;
- preuves de fallback wild / legacy ;
- documentation/reporting du lot.

### Exclu volontairement
- switch volontaire adverse ;
- scripts trainer/boss ;
- targeting riche ;
- doubles ;
- simulation multi-tour / lookahead ;
- nouvelle plomberie runtime ;
- changement UI/runtime/host ;
- refonte large de `battle_session.dart` ;
- framework d'IA générique.

## 5. Classification initiale des sujets

### `required_now`
- extension minimale du seam `BattleOpponentPolicy` au replacement forcé adverse ;
- consommation de cette décision dans `battle_session_scheduler.dart` ;
- maintien d'un fallback faible / legacy honnête ;
- preuves pures low / mid / high sur le seam ;
- preuves d'intégration trainer / wild / legacy sur le scheduler ;
- garde-fou PP pour éviter qu'un gros move vide biaise le scoring ;
- analyze et tests `map_battle` ;
- smoke runtime ciblé pour confirmer que le routing trainer/wild existant reste sain ;
- report ultra complet.

### `fix_now_small`
- ignorer explicitement les réserves K.O. avant d'interroger la policy ;
- garde-fou qui exige que la policy retourne bien une option de replacement fournie par le scheduler ;
- réalignement des commentaires de `battle_session.dart` avec la nouvelle frontière du seam.

### `document_now_only`
- le runtime n'a pas besoin d'être rouvert : le routing produit -> policy existe déjà ;
- les tests `battle_decision_request_test.dart` et la surface joueur de remplacement forcé restent inchangés ;
- `battle_session.dart` n'est touché qu'à la marge documentaire, pas comme cerveau de difficulté.

### `defer_not_lot5`
- switch volontaire adverse ;
- scripts trainer/boss ;
- targeting riche ;
- doubles ;
- multi-turn lookahead ;
- scoring massif / type pressure avancée ;
- framework d'IA / registry de policies.

## 6. Fichiers lus

Docs / reports lus :
- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/combat-ui-ai-audit-and-roadmap.md`
- `reports/combat-ui-ai-implementation-roadmap.md`
- `reports/lot-3-battle-opponent-policy-seam-report.md`
- `reports/lot-4-difficulty-routing-report.md`
- `reports/lot-4b-difficulty-authoring-ui-hardening-report.md`
- `reports/lot-4c-battle-ui-sprites-zone-backgrounds-corrective-report.md`
- `reports/lot-4d-battle-scene-responsive-staging-report.md`
- `reports/lot-4e-battle-ui-visual-lock-report.md`
- `reports/lot-4f-portrait-battle-ui-hardening-report.md`

Battle-core lu :
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_stats.dart`

Runtime / routing lu :
- `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

Tests lus :
- `packages/map_battle/test/battle_opponent_policy_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`

## 7. Fichiers modifiés

Fichiers effectivement modifiés dans ce lot :
- `packages/map_battle/lib/src/battle_opponent_policy.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/test/battle_opponent_policy_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `reports/lot-5-trainer-difficulty-behavior-lift-report.md`

Aucun fichier supprimé.
Aucun fichier runtime, host, map_core ou map_editor modifié.

## 8. Fichiers volontairement non touchés

Volontairement non touchés pour éviter la dérive :
- `packages/map_runtime/lib/src/presentation/flame/runtime_trainer_battle_overrides.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/trainer_battle_request.dart`
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- toute la surface UI Flame des lots 4c/4d/4e/4f

Justification :
- le runtime route déjà honnêtement `battleDifficulty` vers `BattleOpponentPolicy` ;
- le lot 5 sain est un lot battle-local, pas un lot de nouvelle plomberie ;
- le switch volontaire adverse aurait nécessité un élargissement bien plus large des seams.

## 9. Validations réellement relancées

### Rouge initial (avant implémentation)

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart
```

Résultat : rouge.

Causes observées :
- `BattleOpponentReplacementOption` inexistant ;
- `chooseReplacement(...)` inexistant sur `BattleOpponentPolicy` ;
- les tests d'intégration mid/high échouaient encore sur le fallback historique `status_wall`.

### Vert ciblé après implémentation

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart
```

Résultat : vert.

### Revalidation ciblée après review séparée

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart
```

Résultat : vert après ajout des tests `0 PP`.

### Analyze battle

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart analyze
```

Résultat : vert (`No issues found!`).

### Suite battle complète

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart test
```

Résultat : vert (suite complète `map_battle`).

### Smoke runtime ciblé

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat : vert.

Justification du smoke runtime :
- même sans toucher le runtime, ce test confirme que le routing wild/trainer existant n'a pas été cassé et que le lot 5 reste branché sur le chemin produit réel déjà en place.

### Validations volontairement non relancées
- `map_core`, `map_editor`, host complet : non relancés, car aucun fichier de ces surfaces n'a été touché.

## 10. Résultats réellement obtenus

Résultats concrets :
- le replacement adverse trainer après K.O. n'est plus systématiquement `premier réserve utilisable` ;
- le comportement dépend réellement du profil injecté par la difficulté trainer ;
- le fallback faible / legacy / wild reste honnête et stable ;
- les moves offensifs épuisés à `0 PP` ne sont plus traités comme une vraie menace lors du replacement ;
- le switch volontaire adverse n'a pas été implémenté ;
- `battle_session.dart` ne redevient pas le cerveau global de la difficulté ;
- aucun faux framework d'IA n'a été introduit.

## 11. Décisions retenues / rejetées sujet par sujet

### Retenues
1. **Étendre le seam existant au replacement forcé adverse**
   - retenu ;
   - c'est la plus petite extension cohérente du seam lot 3 ;
   - elle garde la difficulté hors de `battle_session.dart`.

2. **Garder le runtime inchangé**
   - retenu ;
   - `trainer difficulty -> BattleOpponentPolicy` existe déjà ;
   - ajouter un nouveau champ/request aurait été de la plomberie inutile.

3. **Heuristique replacement moyenne minimale**
   - retenue : meilleur move offensif brut **encore utilisable**.

4. **Heuristique replacement haute minimale**
   - retenue : `expected power + speed pressure + health pressure`, seulement pour des candidats offensifs et seulement sur des moves encore utilisables.

5. **Fallback si aucun vrai edge offensif**
   - retenu : premier remplaçant légal.

### Rejetées
1. **Switch volontaire adverse**
   - rejeté / différé ;
   - obligerait à rouvrir l'arbitrage inter-familles d'actions (`fight` vs `switch`) ;
   - lot trop large pour rester honnête.

2. **Type pressure avancée**
   - rejetée ;
   - possible techniquement, mais trop coûteuse pour un lot 5 minimal.

3. **Simulation multi-tour / scoring complexe**
   - rejetée ;
   - dérive directe vers une IA riche non demandée.

4. **Nouveau framework / registry de policies**
   - rejeté ;
   - aucun besoin immédiat ;
   - blast radius et dette inutile.

## 12. Description précise du comportement replacement retenu

Le comportement replacement retenu est volontairement petit.

### Profil faible / fallback legacy
- policy : `BattleFirstLegalOpponentPolicy`
- replacement : premier remplaçant légal utilisable
- comportement identique ou quasi identique à l'historique du dépôt

### Profil moyen
- policy : `BattleHighestPowerOpponentPolicy`
- replacement : choisit le remplaçant dont le meilleur move offensif **encore utilisable** a la plus forte puissance brute
- aucun calcul de dégâts complet
- aucun typage contextuel
- si tous les remplaçants sont purement statut ou n'ont plus de PP sur leurs moves offensifs, fallback au premier légal

### Profil élevé
- policy : `BattleHighestExpectedPowerOpponentPolicy`
- replacement : choisit le remplaçant offensif ayant le meilleur score minimal :
  - expected offensive pressure (puissance * précision)
  - plus une petite pondération de vitesse
  - plus une petite pondération de santé restante
- les candidats non offensifs, ou offensifs mais sans PP utilisable, restent à score nul
- si personne n'a d'edge offensif réel, fallback au premier légal

Cette heuristique reste explicitement bornée :
- pas de type pressure avancée ;
- pas de lecture de `BattleSession` ;
- pas de lookahead ;
- pas de simulation de damage roll complet ;
- pas d'arbitrage `switch vs fight`.

## 13. Description précise du comportement switch éventuel

Switch volontaire adverse : **non implémenté**.

Raison :
- le seam existant restait conçu pour arbitrer à l'intérieur d'une famille d'action ;
- le switch volontaire ouvrirait immédiatement la question `fight ou switch ?` ;
- cela forcerait des garde-fous anti-thrash, des choix de rareté et une heuristique d'opportunité, donc un lot plus large et plus risqué.

Décision nette : `switch volontaire adverse = defer_not_lot5`.

## 14. Justification des seams choisis

Seam retenu : **extension minimale de `BattleOpponentPolicy`**.

Pourquoi ce seam :
- il existait déjà comme point de sortie de la logique adverse hors de `battle_session.dart` ;
- il est déjà le point où la difficulté trainer produit arrive concrètement ;
- l'étendre à une seconde question étroite (`quel remplaçant déjà légal choisir ?`) est plus sain que créer une nouvelle hiérarchie parallèle ;
- cela garde le comportement battle-local et testable.

Pourquoi ne pas passer `BattleSession` entière :
- cela aurait réouvert exactement le problème que lot 3 voulait fermer ;
- la policy n'a pas besoin de la queue, des requests, ni de l'état complet ;
- le scheduler peut lui fournir des options de replacement déjà légales, ce qui suffit pour ce lot.

Pourquoi le scheduler est le bon call site :
- le replacement ennemi après K.O. s'y décidait déjà ;
- il était donc plus propre d'y remplacer le `first usable reserve` par la policy que de déplacer cette responsabilité ailleurs.

## 15. Incidents rencontrés

1. **Worktree sale hors scope dès le départ**
   - bruit existant dans `examples/playable_runtime_host` et `examples/.DS_Store` ;
   - laissé intact ;
   - documenté honnêtement.

2. **Premier rouge de TDD sur API manquante**
   - attendu et utile ;
   - le seam `chooseReplacement(...)` n'existait pas encore.

3. **Seconde erreur rouge sur fixture pure**
   - les tests purs utilisaient initialement `BattleCombatantData` là où le seam attend un `BattleCombatant` ;
   - corrigé sans changer l'architecture retenue.

4. **Review séparée d'abord silencieuse puis finalement utile**
   - première attente : timeout ;
   - retour asynchrone final : vrai finding sur les moves à `0 PP` ;
   - correction intégrée avant clôture du lot.

## 16. Retour des sub-agents

### Banach — battle-core / seam design
Conclusion utile :
- le replacement trainer après K.O. se décide bien dans `battle_session_scheduler.dart`, pas dans la policy actuelle ;
- le seam sain consiste à injecter un choix de reserve à ce niveau ;
- le switch volontaire adverse paraît être une dérive probable.

### Linnaeus — runtime / produit / anti-plomberie
Conclusion utile :
- le routing produit `battleDifficulty -> BattleOpponentPolicy` existe déjà ;
- wild battles et trainers sans difficulté explicite retombent déjà sur le fallback historique ;
- le lot 5 n'a pas besoin de rouvrir la plomberie runtime.

### Tesla — testing / non-régression
Conclusion utile :
- meilleure stratégie TDD : tests purs sur le seam + tests d'intégration scheduler ;
- `wild fallback` et `legacy fallback` doivent être prouvés ;
- recommandation nette de **déférer le switch volontaire**.

## 17. Retour du reviewer séparé

Review séparée tentée via sub-agent dédié.

Résultat final utile : **un finding réel, corrigé avant clôture**.

Finding reviewer :
- le scoring replacement comptait initialement encore les moves offensifs sans `PP` utilisable ;
- un remplaçant pouvait donc être jugé menaçant grâce à un gros move déjà vide ;
- dans le pire cas, cela pouvait conduire à choisir un remplaçant incapable de produire la pression offensive promise, voire à exposer plus tard le `StateError` ennemi si aucun move utilisable n'existait.

Résolution appliquée :
- `_bestDamagingMoveScore(...)` ignore maintenant les moves `!move.hasUsablePp` ;
- un test pur et un test d'intégration scheduler verrouillent ce cas.

Aucun autre finding bloquant n'a été remonté.

## 18. Critique explicite du prompt lui-même

### Parties très utiles
- la priorité absolue donnée au replacement intelligent minimal ;
- l'insistance sur la sobriété et l'honnêteté produit ;
- l'interdiction de transformer `battle_session.dart` en cerveau global ;
- l'exigence de preuves concrètes wild/legacy/trainer.

### Parties discutables
- demander à la fois replacement et switch volontaire dans le même lot, tout en posant des garde-fous très stricts contre tout élargissement du seam : dans ce repo réel, cela pousse naturellement à différer le switch volontaire.

### Parties trop rigides
- l'exigence d'inclure le contenu complet de tous les fichiers modifiés **y compris le report créé** est récursivement impossible si on l'applique littéralement au report lui-même.

### Resserrement volontaire appliqué
- j'ai resserré le lot à **replacement only** ;
- j'ai refusé de traiter le switch volontaire adverse ;
- j'ai refusé d'ouvrir une nouvelle plomberie runtime.

Pourquoi :
- c'était la seule façon de garder le lot 5 petit, net, crédible et battle-local.

## 19. Autocritique finale

Points forts :
- le lot donne enfin un effet gameplay battle réel à la difficulté trainer ;
- le blast radius reste petit ;
- la preuve TDD est honnête ;
- wild/legacy restent stables ;
- le reviewer a effectivement trouvé un angle mort utile, et il a été refermé avant la clôture.

Limites assumées :
- l'heuristique haute reste très simple et non contextuelle ;
- elle ne lit pas le matchup type réel, donc le replacement "intelligent" reste modeste ;
- le switch volontaire adverse n'est pas traité.

## 20. État git final utile

L'état git final inclut :
- le bruit initial hors scope inchangé ;
- les fichiers battle modifiés par ce lot ;
- ce report.

Un état git final exact a été rerelé à la fin de la rédaction et figure plus bas dans la section dédiée.

## 21. Checklist finale

- [x] ai-je bien gardé le lot 5 petit et borné ?
- [x] ai-je bien amélioré le replacement trainer de manière réelle ?
- [x] ai-je bien relié ce comportement à la difficulté authorée ?
- [x] ai-je évité de transformer `battle_session.dart` en cerveau global ?
- [x] ai-je évité un framework d’IA générique ?
- [x] ai-je évité scripts trainer/boss ?
- [x] ai-je évité targeting riche / doubles / multi-tour ?
- [x] ai-je écrit des tests qui prouvent vraiment le comportement ?
- [x] ai-je gardé les wild battles sur un fallback honnête si rien n’est authoré ?
- [x] ai-je été honnête sur ce qui est réellement supporté ?
- [x] ai-je relancé les validations utiles ?
- [x] ai-je utilisé des sub-agents si utile ?
- [x] ai-je tenté une review séparée si possible ?
- [x] ai-je inclus le contenu complet de tous les fichiers touchés dans le rapport, à l’exception récursive du report lui-même ?
- [x] ai-je évité toute écriture git interdite ?

## 22. Décision finale nette

**Décision : lot 5 réussi.**

Nuance honnête :
- il est réussi sur son objectif central, à savoir un **replacement trainer intelligent minimal, honnête et borné** ;
- le switch volontaire adverse est **explicitement refusé/différé** pour préserver la santé de l'architecture et la vérité produit.

---

## Annexe A — Ce que les tests prouvent

Les tests ajoutés/prolongés prouvent réellement que :
- le seam `BattleOpponentPolicy` sait maintenant choisir un replacement adverse ;
- les profils faible / moyen / élevé ne choisissent pas le même remplaçant ;
- le scheduler enemy auto-replace consomme cette décision au vrai moment du K.O. ;
- les trainers sans difficulté explicite gardent le fallback historique ;
- les wild battles gardent le fallback historique ;
- les réserves K.O. sont ignorées avant consultation de la policy ;
- les moves offensifs sans PP utilisable n'influencent plus le scoring.

Ce qu'ils ne prouvent pas :
- une intelligence contextuelle riche ;
- un switch volontaire adverse ;
- un raisonnement matchup par matchup complet.

## Annexe B — Commandes exécutées et résultats synthétiques

```text
[pré-gates]
git status --short --untracked-files=all                     -> worktree sale hors scope battle
git diff --stat                                              -> bruit host initial confirmé
git ls-files --others --exclude-standard                     -> examples/.DS_Store

[audit]
rg --files -g 'AGENTS.md'                                    -> uniquement AGENTS root
rg/sed ciblés sur docs, reports, battle_session, scheduler,
battle_opponent_policy, tests, runtime overrides             -> audit local terminé

[tests rouges]
cd packages/map_battle && dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart
-> rouge attendu : seam replacement manquant puis attentes mid/high en échec

[tests ciblés verts]
cd packages/map_battle && dart test test/battle_opponent_policy_test.dart test/battle_switch_test.dart
-> vert

[review]
review séparée sub-agent                                      -> finding PP 0 remonté puis corrigé

[validations finales]
cd packages/map_battle && dart analyze                       -> vert
cd packages/map_battle && dart test                          -> vert
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
-> vert
```

## Annexe C — État git final exact
 M examples/playable_runtime_host/ios/Runner/Info.plist
 M examples/playable_runtime_host/lib/main.dart
 M packages/map_battle/lib/src/battle_opponent_policy.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
 M packages/map_battle/test/battle_opponent_policy_test.dart
 M packages/map_battle/test/battle_switch_test.dart
?? examples/.DS_Store
?? reports/lot-5-trainer-difficulty-behavior-lift-report.md

### git diff --stat

```text
 .../playable_runtime_host/ios/Runner/Info.plist    |   4 +
 examples/playable_runtime_host/lib/main.dart       |  61 +++--
 .../map_battle/lib/src/battle_opponent_policy.dart | 175 +++++++++++-
 packages/map_battle/lib/src/battle_session.dart    |  11 +-
 .../lib/src/battle_session_scheduler.dart          |  48 +++-
 .../test/battle_opponent_policy_test.dart          | 244 +++++++++++++++++
 packages/map_battle/test/battle_switch_test.dart   | 303 +++++++++++++++++++++
 7 files changed, 801 insertions(+), 45 deletions(-)
```

## Annexe D — Contenu complet des fichiers modifiés

Note honnête importante :
- cette annexe inclut le contenu complet de tous les **fichiers code/tests** modifiés par le lot 5 ;
- ce report n'est pas ré-embarqué dans sa propre annexe, sinon l'annexe deviendrait récursive et infinie.

### `packages/map_battle/lib/src/battle_opponent_policy.dart`

````dart
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

````

### `packages/map_battle/lib/src/battle_session.dart`

````dart
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

````

### `packages/map_battle/lib/src/battle_session_scheduler.dart`

````dart
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
  final enemyReplacementIndex = _chooseEnemyReplacementIndex(
    session: session,
    reserve: turn.enemySide.reserve,
  );
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
    final nextReserveIndex = step.side == BattleSideId.enemy
        ? _chooseEnemyReplacementIndex(
            session: session,
            reserve: turn.side(step.side).reserve,
          )
        : session._firstUsableReserveIndex(turn.side(step.side).reserve);
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

int? _chooseEnemyReplacementIndex({
  required BattleSession session,
  required List<BattleCombatant> reserve,
}) {
  final legalReplacementOptions = <BattleOpponentReplacementOption>[];
  for (var i = 0; i < reserve.length; i++) {
    final combatant = reserve[i];
    if (!combatant.isFainted) {
      legalReplacementOptions.add(
        BattleOpponentReplacementOption(
          reserveIndex: i,
          combatant: combatant,
        ),
      );
    }
  }
  if (legalReplacementOptions.isEmpty) {
    return null;
  }

  final selectedOption = session.opponentPolicy.chooseReplacement(
    legalReplacementOptions:
        List<BattleOpponentReplacementOption>.unmodifiable(
      legalReplacementOptions,
    ),
  );
  if (!legalReplacementOptions.contains(selectedOption)) {
    throw StateError(
      'BattleOpponentPolicy doit retourner une des options de replacement légales fournies par le scheduler.',
    );
  }
  return selectedOption.reserveIndex;
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

````

### `packages/map_battle/test/battle_opponent_policy_test.dart`

````dart
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

````

### `packages/map_battle/test/battle_switch_test.dart`

````dart
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
          moves: <BattleMoveData>[_waitingMove()],
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
          moves: <BattleMoveData>[_waitingMove()],
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
          moves: <BattleMoveData>[_waitingMove()],
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
          moves: <BattleMoveData>[_waitingMove()],
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
          moves: <BattleMoveData>[_waitingMove()],
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

````
