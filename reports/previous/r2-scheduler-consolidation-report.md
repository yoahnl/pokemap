# R2 — Scheduler Consolidation Report

## 1. Résumé exécutif honnête

`R2 — Scheduler Consolidation` est **réussi**.

Le dépôt avait déjà un scheduler local réel via `BattleTurnQueue`, mais la frontière restait trop dense dans `packages/map_battle/lib/src/battle_session.dart`. Ce passage extrait maintenant ce seam dans un unique fichier privé dédié, sans widening de surface, sans nouveau framework générique, sans nouvelle mécanique, et sans dérive vers `R3`, `R4` ou `H3`.

Le résultat concret est le suivant :

- `BattleSession.applyChoice` garde la frontière `request -> action choisie`.
- un `_BattleTurnPlan` explicite distingue l'action rapportée du tour et les étapes réellement planifiées en queue.
- `_consumeTurnPlan` centralise la consommation de queue.
- la suspension / reprise locale n'est plus noyée dans `battle_session.dart`.
- l'assemblage de `BattleTurnResult` est maintenant explicitement séparé de l'exécution.

Le slice produit supporté n'a pas été élargi :

- pas de `Struggle`
- pas de widening de `BattleDecisionRequest`
- pas de widening targeting
- pas de forced switch / self switch / phazing
- pas de nouvelle famille de conditions
- pas d'IA/difficulté

Les validations utiles sont vertes :

- `dart analyze` et `dart test` sur `packages/map_battle`
- `flutter test` ciblé sur le runtime battle
- `flutter test` ciblé sur le host golden slice

Les docs canoniques ont été réalignées honnêtement après `R2` :

- le canon battle dit désormais explicitement que l'état actuel est **après R2**
- la suite officielle après `R2` n'est plus une étape unique, mais une branche conditionnelle `R4` ou `R3` selon la mécanique visée

Verdict net :

- `R2` réussi : **oui**
- seam scheduler réellement consolidé : **oui**
- docs canoniques réellement réalignées : **oui**
- prochaine étape officielle après `R2` : **conditionnelle**
  - `R4` si le besoin suivant est `switch / replacement / targeting`-centric
  - `R3` si le besoin suivant est `condition`-centric

## 2. Pré-gates réellement exécutés + résultats

Pré-gates exécutés au début du passage, exactement comme demandé :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats exacts observés au début du passage :

- `git status --short --untracked-files=all`
  - aucune sortie
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - aucune sortie

Interprétation :

- malgré l'avertissement du prompt sur un worktree possiblement dirty, le dépôt était **propre** au début réel de `R2`
- cet état propre a été traité comme baseline de travail
- aucun reset ni discard n'a été tenté

## 3. État git initial exact et interprétation

État git initial exact :

- tracked modifications : aucune
- untracked files : aucun
- diff stat : vide

Interprétation froide :

- `R2` n'a pas eu à composer avec un reliquat non commit de `R1`
- le prompt avait raison de demander un constat exact, mais dans ce cas précis la suspicion d'un repo déjà dirty ne s'est pas vérifiée

## 4. Méthode réellement suivie

Méthode suivie, dans l'ordre :

1. pré-gates read-only et constat exact du worktree
2. relecture ciblée du seam scheduler réel dans `map_battle`
3. relecture des tests battle qui verrouillent déjà switch/hazards/reprise
4. relecture des tests runtime/host qui consomment la vérité battle
5. consultation ciblée de Showdown locale uniquement pour confirmer l'intuition de séparation `choice -> queue -> execution`, sans singer son architecture
6. classification explicite des sujets `R2`
7. choix d'une seule stratégie : un unique `part` privé dédié au scheduler, sans framework générique
8. implémentation minimale
9. validations battle, runtime et host
10. review séparée finale, puis fermeture du seul trou de couverture signalé
11. revalidation battle
12. réalignement de la doc canonique utile
13. rédaction du présent report

Skills/plugins effectivement utilisés :

- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:dispatching-parallel-agents`
- `superpowers:verification-before-completion`
- `game-studio:game-studio`
- `game-studio:web-game-foundations`

Usage réel :

- `superpowers` a été utile pour la discipline de cadrage, la distribution des audits et la vérification avant clôture
- `game-studio` a été beaucoup moins central ; il a surtout servi de garde-fou initial pour confirmer qu'on n'était ni sur un sujet frontend ni sur un playtest produit, mais sur une consolidation d'architecture battle pure Dart

## 5. Périmètre inclus / exclu

### Inclus

- consolidation du seam scheduler déjà existant
- réduction de densité scheduler dans `packages/map_battle/lib/src/battle_session.dart`
- clarification explicite :
  - action choisie / action rapportée
  - action planifiée
  - exécution de queue
  - suspension / reprise
  - assemblage du `BattleTurnResult`
- test de non-régression ciblé sur la sémantique de reprise
- mise à jour de la doc canonique utile après `R2`

### Exclus volontairement

- `R1` bis
- `Struggle`
- widening requests / targeting / replacement
- `R3`
- `R4`
- `H3`
- runtime/editor/host source edits
- framework queue générique
- grande réécriture documentaire historique

## 6. Classification initiale des sujets

Classification retenue avant patch :

- extraction / clarification de la planification locale du tour : `required_now`
- extraction / clarification de l'exécution de queue : `required_now`
- clarification du seam suspension / reprise : `required_now`
- clarification du turn tail (`endOfTurn`, `postTurnChecks`, `autoSwitch`, `replacementRequired`) : `required_now`
- éventuelle création d'un nouveau fichier scheduler : `required_now`
- éventuelle mise à jour doc canonique : `document_now_only`
- retouches runtime/editor/host source : `defer_not_r2`
- widening requests / targeting / replacement : `defer_not_r2`
- condition lifecycle / side-condition framework : `defer_not_r2`
- nouvelle mécanique / `Struggle` / H3 : `defer_not_r2`
- ajout de tests de verrouillage R2 : `fix_now_small`

## 7. Fichiers lus

### Battle core

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_stealth_rock.dart`
- `packages/map_battle/lib/src/battle_spikes.dart`
- `packages/map_battle/lib/src/battle_topology.dart`

### Tests battle

- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_stealth_rock_test.dart`
- `packages/map_battle/test/battle_spikes_test.dart`

### Runtime / host vérité produit

- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`

### Docs canoniques

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r1-battleable-slice-hardening-report.md`
- `reports/r1-closure-polish-report.md`

### Référence Showdown locale, utilisée seulement pour cadrage d'intuition

- `pokemon-showdown-master/sim/battle-queue.ts`
- `pokemon-showdown-master/sim/battle.ts`
- `pokemon-showdown-master/sim/battle-actions.ts`
- `pokemon-showdown-master/sim/side.ts`

### Fichiers AGENTS / consignes locales

- `AGENTS.md` à la racine du dépôt
- aucune autre consigne `AGENTS.md` plus profonde détectée dans le repo

## 8. Design retenu avant patch

### Frontière scheduler réelle avant patch

Avant `R2`, le dépôt avait déjà un vrai scheduler local, mais la frontière restait trop dense dans `battle_session.dart`.

Ce qui relevait réellement du scheduler :

- remplacement forcé joueur inter-tour
- reprise de tour suspendu
- planification initiale du tour
- consommation de queue
- insertion du turn tail
- exécution des `BattleQueueStep`
- capture de continuation suspendue
- assemblage du `BattleTurnResult`
- petits carriers privés du scheduler (`_PendingTurnContinuation`, `_QueuedTurnContext`, `_OrderedBattleAction`, etc.)

Ce qui relevait déjà du métier combat pur et devait rester dans `BattleSession` :

- frontière request / choice
- résolution d'action forcée
- choix d'action ennemi
- résolution des moves
- dégâts / accuracy / crit / speed
- conditions moteur
- hazards / entry hazards
- switch resolution métier
- outcome

### Nouvelle frontière visée

Une seule stratégie a été retenue :

- créer **un seul** fichier privé `part` : `packages/map_battle/lib/src/battle_session_scheduler.dart`
- y déplacer uniquement les responsabilités scheduler
- garder `BattleSession.applyChoice` comme façade lisible du flow principal
- ne publier aucun nouveau contrat
- ne pas modifier `battle_queue.dart`, car la queue existante était déjà la bonne primitive locale

### Morceaux sortis de `battle_session.dart`

Sont sortis dans le nouveau seam scheduler privé :

- planification locale du tour via `_BattleTurnPlan`
- planification de remplacement inter-tour
- planification de reprise d'un tour suspendu
- consommation de queue via `_consumeTurnPlan`
- exécution des steps de queue
- insertion du turn tail
- capture / restauration de `_PendingTurnContinuation`
- contexte mutable `_QueuedTurnContext`
- assemblage de `BattleTurnResult`
- ordre local des actions supportées

### Morceaux laissés dans `battle_session.dart`

Sont restés dans `battle_session.dart` :

- `decisionRequest`
- `getAvailableChoices`
- `_buildDecisionRequest`
- `_choiceToAction`
- `_illegalChoiceStateError`
- `_resolveForcedAction`
- `_chooseEnemyAction`
- toutes les règles métier de résolution combat
- le calcul d'outcome

### Pourquoi cette stratégie et pas une autre

Cette stratégie a été retenue parce qu'elle :

- réduit réellement la densité scheduler dans `battle_session.dart`
- clarifie explicitement le pipeline `choice -> plan -> consume -> result`
- évite une explosion de fichiers morts
- évite d'exposer des APIs internes nouvelles
- n'imite pas Showdown au-delà de l'intuition utile

## 9. Décisions retenues / rejetées sujet par sujet

### Extraction / clarification de la planification locale du tour

Décision : **retenue**

Implémentation :

- introduction de `_BattleTurnPlan`
- séparation explicite entre :
  - `reportedPlayerAction` / `reportedEnemyAction`
  - `initialSteps`
  - `allowTurnTailInsertion`

Pourquoi c'est bien `R2` :

- on clarifie un seam déjà vivant
- on n'élargit pas les contracts
- on ne change pas le slice produit supporté

### Extraction / clarification de l'exécution de queue

Décision : **retenue**

Implémentation :

- `_consumeTurnPlan`
- `_executeQueueStep`
- helpers d'exécution par type de `BattleQueueStep`

Pourquoi c'est bien `R2` :

- le moteur consommait déjà une vraie queue
- on déplace l'orchestration, pas la mécanique

### Clarification du seam suspension / reprise

Décision : **retenue**

Implémentation :

- conservation et déplacement de `_PendingTurnContinuation`
- reprise via `_planPendingTurnResumption`
- test de verrouillage sur les actions rapportées du tour suspendu

Point important :

- la reprise ne raconte pas un nouveau tour
- elle continue le tour logique déjà commencé

### Clarification du turn tail

Décision : **retenue**

Implémentation :

- `allowTurnTailInsertion`
- `_appendTurnTailWhenActionPhaseDrains`

Effet :

- les vrais tours insèrent `endOfTurn` puis `postTurnChecks`
- les remplacements inter-tour ne prétendent plus être un vrai tour complet

### Création d'un ou plusieurs nouveaux fichiers scheduler

Décision : **retenue, mais resserrée à un seul fichier**

Pourquoi :

- le prompt autorisait `1 à 3` nouveaux fichiers
- le dépôt n'en avait pas besoin
- un seul `part` privé suffisait à clarifier le seam sans zoo d'abstractions

### Mise à jour doc canonique

Décision : **retenue**

Pourquoi :

- `R2` change réellement la vérité structurelle canonique
- après `R2`, la suite officielle n'est plus une étape unique

### Modifications explicitement rejetées

Décisions rejetées :

- modification de `battle_queue.dart`
- modification de `battle_action.dart`
- modification de `battle_resolution.dart`
- modification runtime/editor/host source
- widening de `BattleDecisionRequest`
- `Struggle`
- toute ouverture `R3`, `R4` ou `H3`

## 10. Justification précise des fichiers modifiés

### `packages/map_battle/lib/src/battle_session.dart`

Pourquoi touché :

- c'était le foyer de densité scheduler à réduire

Type de modification :

- ajout du `part 'battle_session_scheduler.dart';`
- simplification de `applyChoice` autour de `plan -> consume -> result`
- suppression des helpers scheduler déplacés

### `packages/map_battle/lib/src/battle_session_scheduler.dart`

Pourquoi créé :

- matérialiser le seam scheduler consolidé sans élargir la surface publique

Type de modification :

- nouveau fichier privé `part`
- planification locale du tour
- consommation de queue
- reprise locale
- assemblage du `BattleTurnResult`
- carriers privés du seam

### `packages/map_battle/test/battle_stealth_rock_test.dart`

Pourquoi touché :

- verrouiller la sémantique `reported action != replacement step` sur un tour repris après KO d'entrée

### `packages/map_battle/test/battle_spikes_test.dart`

Pourquoi touché :

- fermer le trou de couverture miroir signalé par le reviewer séparé

### `docs/combat/battle-canonical-state-v3.1.md`

Pourquoi touché :

- le canon battle devait devenir honnête **après R2**

### `docs/combat/battle-roadmap-canonical-v3.1.md`

Pourquoi touché :

- la roadmap devait cesser d'afficher une prochaine étape unique après `R2`

### `reports/r2-scheduler-consolidation-report.md`

Pourquoi créé :

- livrable demandé

## 11. Justification des fichiers volontairement non touchés

### `packages/map_battle/lib/src/battle_queue.dart`

Non touché volontairement.

Pourquoi :

- la queue locale existante était déjà le bon contrat concret
- `R2` devait consolider l'orchestration autour d'elle, pas la réinventer

### `packages/map_battle/lib/src/battle_action.dart`

Non touché volontairement.

Pourquoi :

- la distinction `PlayerBattleChoice` / `BattleAction` existait déjà réellement
- le besoin R2 était d'ajouter un niveau `plan`, pas de modifier les actions elles-mêmes

### `packages/map_battle/lib/src/battle_resolution.dart`

Non touché volontairement.

Pourquoi :

- `BattleTurnResult` était déjà le bon contrat observable
- il fallait clarifier quand il est assemblé, pas le widener

### Runtime / editor / host source

Non touchés volontairement.

Pourquoi :

- `R2` ne devait pas élargir le slice produit
- la vérité produit devait être vérifiée par tests, pas retouchée opportunistement

### Docs historiques hors canon direct

Non touchées volontairement.

Pourquoi :

- `R2` n'était pas un nouveau chantier de truth alignment large
- seules les docs canoniques directement impactées ont été mises à jour

## 12. Validations réellement relancées

Validations relancées par moi :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test   test/runtime_battle_move_bridge_test.dart   test/runtime_battle_setup_mapper_test.dart   test/runtime_battle_outcome_apply_test.dart   test/runtime_battle_combatant_seed_builder_test.dart   test/battle_overlay_component_test.dart   test/wild_battle_end_to_end_flow_test.dart   test/phase_a_golden_battle_slice_smoke_test.dart
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test   test/project_loader_page_test.dart   test/runtime_launch_save_test.dart   test/runtime_demo_party_seed_test.dart   test/phase_a_golden_slice_launch_test.dart
```

Valiations auxiliaires relancées par le reviewer séparé :

- `dart analyze lib/src/battle_session.dart lib/src/battle_session_scheduler.dart test/battle_stealth_rock_test.dart`
- `dart test test/battle_stealth_rock_test.dart`
- `flutter test test/phase_a_golden_battle_slice_smoke_test.dart`
- `flutter test test/wild_battle_end_to_end_flow_test.dart`
- puis après sa finding unique, `dart analyze test/battle_spikes_test.dart`
- puis `dart test test/battle_spikes_test.dart test/battle_stealth_rock_test.dart`

Validations volontairement **non relancées** :

- `flutter analyze` sur `map_runtime`
- `flutter analyze` sur le host
- `map_editor`

Justification :

- aucun code runtime/editor/host source n'a été modifié
- le prompt minimum de `R2` demandait battle analyze/test et runtime/host tests
- ajouter des analyzes hors périmètre aurait surtout été du temps machine supplémentaire, pas un gain direct de vérité sur la consolidation scheduler

## 13. Résultats réellement obtenus

### Battle

- `dart analyze`
  - `Analyzing map_battle...`
  - `No issues found!`
- `dart test`
  - `All tests passed!`

### Runtime ciblé battle

- `flutter test ...`
  - `All tests passed!`

### Host

- `flutter test ...`
  - `All tests passed!`

### Effet structurel mesurable

- `packages/map_battle/lib/src/battle_session.dart` : **2646 lignes avant audit initial, 1805 lignes après R2**
- nouveau seam privé `packages/map_battle/lib/src/battle_session_scheduler.dart` : **918 lignes**

Interprétation :

- `battle_session.dart` reste gros, mais sa densité scheduler a réellement baissé
- l'extraction n'a pas été cosmétique : elle a retiré du fichier principal la quasi-totalité du plumbing de queue/résumption/result assembly

## 14. Incidents rencontrés

Incident mineur constaté :

- une commande `rg` improvisée avec des backticks dans le shell a déclenché `zsh: command not found` pour des fragments comme `R1` / `après`
- aucun fichier n'a été modifié à cause de cet incident
- aucun impact repo

Aucun autre incident bloquant.

## 15. Retour des sub-agents

### Laplace — battle-core / architecture

Constat retenu :

- le vrai sujet n'était pas d'inventer un scheduler, mais de sortir l'orchestration scheduler de `battle_session.dart`
- garder dans `battle_session.dart` la frontière publique et les règles métier était la bonne lecture

Retenu : oui

### Dirac — scheduler / queue semantics

Constat retenu :

- la vraie distinction utile était `choice -> resolved action -> planned steps -> pending continuation`
- le plus gros risque de la v2 de l'idée était de fabriquer une fausse abstraction générique

Retenu : oui

### Pasteur — regression / product truth

Constat retenu :

- les vrais garde-fous de vérité produit étaient les tests runtime overlay / golden slice / host
- il fallait vérifier le runtime et le host sans toucher leur code

Retenu : oui

### Huygens — reviewer séparé final

Finding initial :

- un seul trou de couverture restait : la nouvelle sémantique de reprise était verrouillée pour `Stealth Rock`, mais pas encore pour le chemin analogue `Spikes`

Action retenue :

- ajout du même verrouillage ciblé dans `packages/map_battle/test/battle_spikes_test.dart`

Verdict final du reviewer après correctif :

- plus de finding concret
- patch jugé propre dans le périmètre `R2`

## 16. Retour du reviewer séparé

Objections/finding concrets du reviewer :

1. `[P3]` la sémantique la plus sensible du patch était l'invariant suivant : un `BattleTurnResult` repris doit continuer à raconter les actions originales du tour suspendu, et non le switch forcé de reprise
2. cet invariant était déjà verrouillé côté `Stealth Rock`, mais pas encore côté `Spikes`

Ce qui a été retenu :

- finding retenu
- test miroir ajouté dans `battle_spikes_test.dart`

Ce qui a été écarté :

- aucune autre objection structurelle
- aucune accusation de drift `R3/R4/H3`
- aucune accusation de fausse abstraction
- aucune objection documentaire majeure

## 17. Critique explicite du prompt lui-même

### Parties utiles

- l'insistance sur le caractère **déjà existant** du seam scheduler
- l'interdiction d'un framework générique mort
- l'obligation de conserver l'état réel du repo comme baseline
- l'exigence de vérifier la vérité runtime/host malgré un chantier battle-core
- le point explicite sur la suite conditionnelle après `R2`

### Parties discutables

- le prompt pousse très fort sur la réduction de densité dans `battle_session.dart`, ce qui est juste, mais il aurait pu laisser croire que tout ce qui ressemble à du scheduler doit sortir ; en réalité certains points de frontière publique devaient y rester
- l'exigence de “beaucoup de commentaires utiles” est bonne ici parce que `R2` est structurel, mais elle serait trop lourde si appliquée aveuglément à tout petit changement

### Parties trop rigides

- le minimum de validations demandé incluait runtime + host tests même sans modification de leur code ; c'était finalement acceptable et même utile ici, mais c'est plus rigide que strictement nécessaire pour un refactor battle-core pur
- la contrainte implicite “réduire la densité scheduler” pourrait pousser à un faux succès cosmétique si elle n'est pas croisée avec la vraie question de responsabilité ; j'ai volontairement privilégié la seconde

### Ce que j'ai volontairement resserré

- le prompt autorisait `1 à 3` nouveaux fichiers scheduler ; j'ai resserré à **un seul** fichier
- le prompt autorisait potentiellement des touches sur `battle_queue.dart`, `battle_action.dart`, `battle_resolution.dart` ; je les ai laissés intacts parce que le repo n'en avait pas besoin pour un vrai `R2`
- le prompt évoquait `game-studio`, mais le sujet réel était de l'architecture battle pure Dart ; j'ai donc utilisé ce plugin seulement comme garde-fou contextuel léger, pas comme moteur du travail

## 18. Autocritique finale

Ce que je considère solide :

- la réduction réelle de densité scheduler dans `battle_session.dart`
- la clarification explicite `choice -> plan -> consume -> result`
- l'absence de widening opportuniste
- la vérité canonique documentaire après `R2`

Ce qui reste encore limité malgré ce patch :

- `battle_session.dart` reste un gros fichier
- `R2` n'efface pas les limites structurelles du scheduler local ; il le clarifie, il ne le rend pas “large”
- je n'ai pas touché `battle_queue.dart`, ce qui est un choix volontairement conservateur ; si un futur besoin prouve qu'elle est trop étroite, ce sera un sujet ultérieur, pas un manque caché de ce patch

Ce qui pourrait encore être discuté architecturalement :

- la taille du nouveau `battle_session_scheduler.dart` reste importante ; c'est un compromis assumé pour éviter un zoo de fichiers abstraits. Il est plus facile à défendre qu'une dispersion artificielle, mais ce n'est pas encore l'état final idéal d'une architecture mature.

## 19. État git final utile

État git final constaté :

```text
 M docs/combat/battle-canonical-state-v3.1.md
 M docs/combat/battle-roadmap-canonical-v3.1.md
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_spikes_test.dart
 M packages/map_battle/test/battle_stealth_rock_test.dart
?? packages/map_battle/lib/src/battle_session_scheduler.dart
?? reports/r2-scheduler-consolidation-report.md
```

`git diff --stat` final :

```text
 docs/combat/battle-canonical-state-v3.1.md         |  34 +-
 docs/combat/battle-roadmap-canonical-v3.1.md       |  17 +-
 packages/map_battle/lib/src/battle_session.dart    | 937 ++-------------------
 packages/map_battle/test/battle_spikes_test.dart   |  19 +
 packages/map_battle/test/battle_stealth_rock_test.dart  |  19 +
 5 files changed, 121 insertions(+), 905 deletions(-)
```

`git ls-files --others --exclude-standard` final :

```text
packages/map_battle/lib/src/battle_session_scheduler.dart
reports/r2-scheduler-consolidation-report.md
```

Interprétation :

- le diff stat tracked ne compte pas le nouveau fichier untracked, il faut donc croiser `git diff --stat` avec `git status` pour la vérité complète

## 20. Checklist finale

- ai-je gardé le périmètre dans `R2` et pas au-delà ? oui
- ai-je réellement réduit la densité scheduler dans `battle_session.dart` ? oui
- ai-je clarifié action choisie / action planifiée / exécution / reprise ? oui
- ai-je évité de créer un framework générique mort ? oui
- ai-je évité d'ouvrir une nouvelle mécanique ? oui
- ai-je évité toute dérive vers `R3` / `R4` / `H3` ? oui
- ai-je gardé le runtime/host golden slice honnête ? oui
- ai-je mis à jour la doc canonique si nécessaire ? oui
- ai-je réellement relancé les validations utiles ? oui
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je inclus le contenu complet de tous les fichiers touchés ? oui, sauf le report lui-même exclu explicitement pour éviter une récursion absurde
- ai-je évité toute écriture Git interdite ? oui

## 21. Décision finale nette

- `R2` réussi : **oui**
- seam scheduler réellement consolidé : **oui**
- docs canoniques réellement réalignées : **oui**
- prochaine étape officielle après `R2` : **conditionnelle**
  - `R4` si la prochaine mécanique visée est `switch / replacement / targeting`-centric
  - `R3` si la prochaine mécanique visée est `condition`-centric

## 22. Contenu complet de TOUS les fichiers modifiés/créés/supprimés

Note de méthode : le présent report n'est pas recopié dans sa propre annexe, pour éviter une récursion absurde. Tous les autres fichiers touchés le sont ci-dessous en contenu complet.

### `/Users/karim/Project/pokemonProject/docs/combat/battle-canonical-state-v3.1.md`

~~~~md
# Battle Canonical State v3.1

Statut: canon battle actuel du dépôt après `R2 — Scheduler Consolidation`

Date de réalignement: 2026-04-18

## But du document

Ce document est la photographie canonique de l'état battle réel de PokeMap.

Il ne décrit ni une intention, ni une vieille phase, ni une promesse.
Il décrit ce que le dépôt sait réellement faire aujourd'hui, sur la base:

1. du code réel
2. des validations réellement relancées
3. du runtime réellement branché
4. du host et du golden slice réellement versionnés
5. du bootstrap réellement présent
6. de la comparaison locale ciblée avec Pokémon Showdown

Ce document remplace comme source de vérité battle actuelle les anciennes formulations qui racontent encore:

- un handoff runtime -> battle à construire
- une battleabilité encore purement future
- un moteur encore “pré-fondations”

## Résumé exécutif honnête

Le moteur battle PokeMap est déjà réel.

Le dépôt supporte déjà un vrai slice `singles-only` avec:

- une vraie battle loop locale
- un vrai handoff runtime -> battle
- une vraie overlay pilotée par une timeline observable
- de vraies battles wild et trainer
- de vraies réserves côté joueur et côté trainer
- une vraie fuite sauvage
- une vraie capture minimale
- un vrai write-back runtime minimal
- un vrai ordre local priorité / vitesse / Trick Room
- PP / accuracy / crit minimaux réels
- dégâts simples + STAB + effectiveness + immunités
- statuts majeurs `par`, `brn`, `psn`, `tox`
- volatiles bornés `protect`, `recharge`, `chargeThenStrike`
- `rain`, `sandstorm`, `trickRoom`
- switch volontaire
- forced replacement joueur
- auto-switch ennemi
- `Stealth Rock`
- `Spikes`

Le moteur n'est pas proche de Pokémon Showdown au sens structurel large.
L'écart dominant n'est plus l'absence de slice battleable. L'écart dominant est:

- la centralisation résiduelle autour de `packages/map_battle/lib/src/battle_session.dart`
- l'étroitesse des contracts requests / targeting / replacement
- la petitesse d'un scheduler local désormais consolidé mais encore borné
- l'asymétrie entre conditions moteur et side conditions/hazards

La vérité produit actuelle est la suivante:

- un **golden slice battleable versionné** existe réellement
- un **host lançable** existe réellement
- un **bootstrap projet frais générique** existe réellement, mais il n'est pas équivalent à un projet battle-ready générique

Décision canonique après R2:

- la suite officielle n'est plus unique
- si la prochaine mécanique visée est `switch/replacement/targeting`-centric, la branche officielle est `R4`
- si la prochaine mécanique visée est `condition`-centric, la branche officielle est `R3`

## État réel du moteur battle

### Ce qui existe déjà réellement

#### Topologie et état

Le moteur a déjà une vraie topologie singles-bornée:

- `BattleSideId`
- `BattleSlotRef`
- un seul slot actif par side
- réserves réelles des deux côtés

Fichiers pivots:

- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`

#### Requests et décisions

Le moteur expose déjà un vrai request model local via `BattleDecisionRequest`:

- `turnChoice`
- `forcedReplacement`
- `continue`
- `wait`

Ce n'est pas le request model riche de Showdown, mais ce n'est plus un placeholder.

Fichier pivot:

- `packages/map_battle/lib/src/battle_decision.dart`

#### Queue / scheduling local

Le moteur a déjà une vraie queue locale:

- `action`
- `endOfTurn`
- `postTurnChecks`
- `autoSwitch`
- `replacementRequired`

`Run` et `Capture` restent volontairement hors queue.

Après `R2`, ce seam est plus explicite:

- action choisie et action rapportée au tour restent distinctes du plan de queue
- la planification locale du tour est séparée de la consommation de queue
- la suspension / reprise locale n'est plus noyée dans la session principale
- l'assemblage de `BattleTurnResult` est explicitement séparé de l'exécution

Ce seam existe déjà. Il ne faut plus le raconter comme “à créer”.

Fichiers pivots:

- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`

#### Condition engine local

Le moteur a déjà un vrai `BattleConditionEngine` local.

Il sait déjà piloter:

- `runActionAttempt`
- `runHitInterception`
- `runMoveResolved`
- `runForcedContinueTurn`
- `runEndOfTurn`

Ce seam est réel, consommé, et testé.

Fichier pivot:

- `packages/map_battle/lib/src/battle_condition_engine.dart`

#### Résolution de tour

Le moteur résout déjà réellement:

- ordre priorité / vitesse / Trick Room
- accuracy locale
- consommation de PP
- crit minimal
- dégâts simples
- STAB
- effectiveness
- immunités
- statuts majeurs supportés
- volatiles supportés
- field supporté
- switch / replacement / auto-switch
- hazards supportées

Fichier pivot:

- `packages/map_battle/lib/src/battle_session.dart`

#### Restitution observable

Le moteur a déjà une vraie chronologie de tour exploitable via:

- `BattleTurnResult.timeline`

Fichier pivot:

- `packages/map_battle/lib/src/battle_resolution.dart`

### Ce qui est réellement supporté mais borné

- `singles-only`
- un slot actif par side
- targeting local minimal `self/opponent/field/opponentSide/unspecified`
- scheduler local réel, consolidé, et encore borné
- condition engine réel mais borné
- side-level mechanics ouvertes sur deux slices dédiées, pas un framework générique
- write-back runtime réel mais étroit

### Ce qui est fragile

- `Struggle` reste absent et volontairement hors scope R1
- côté joueur, `BattleWaitReason.noLegalChoice` est un dead-end explicite et unsupported ; ce n'est ni un flow gameplay acceptable, ni un support implicite de `Struggle`
- côté ennemi, l'absence totale d'action légale reste un `StateError` explicite ; cette asymétrie est assumée en R1 et ne vaut pas support complet du cas “no move left”
- l'ennemi sans action légale échoue désormais explicitement au lieu de produire un faux `Run`
- tie-break vitesse égale déterministe joueur d'abord
- priorité de switch localement hardcodée
- politique de double KO locale, maintenue explicitement en R1
- ordre d'entrée hazards local `Stealth Rock` puis `Spikes`
- compatibilités legacy dans `BattleMove` et `BattleTypeChart`

### Ce qui n'est pas supporté honnêtement aujourd'hui

- doubles
- targeting riche Showdown
- `selfSwitch` générique
- `forceSwitch` / phazing générique
- terrains
- `Toxic Spikes`
- `Sticky Web`
- abilities
- items
- système générique de side conditions
- event engine Showdown-like

## État réel du runtime battle

### Handoff runtime -> battle

Le handoff runtime -> battle est réel.

Le runtime sait aujourd'hui:

- construire une `WildBattleStartRequest`
- construire une `TrainerBattleStartRequest`
- mapper ces requests vers un `BattleSetup` réel
- résoudre une lineup joueur active + réserves
- construire des seeds combatants réels à partir des données runtime/projet

Fichiers pivots:

- `packages/map_runtime/lib/src/application/battle_start_request.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`

### Bridge moves

Le bridge runtime moves -> battle est réel et volontairement strict.

Il transporte honnêtement le sous-ensemble supporté et refuse explicitement le hors-scope.

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

### Overlay battle

L'overlay est branchée sur la vérité moteur actuelle:

- requests
- timeline
- refresh de session

Fichier pivot:

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

### Write-back

Le write-back runtime est réel, mais étroit.

Ce qu'il sait réellement faire:

- write-back des PV sur la party engagée
- marquage trainer defeated
- capture minimale
- whiteout-lite

Fichier pivot:

- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`

## État réel du bootstrap / seed

### Ce qui existe réellement

- un seed moves embarqué et versionné
- un bootstrap projet frais générique
- un seed de démo explicite et séparé

Fichiers pivots:

- `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`

### Vérité bootstrap honnête

Le bootstrap projet frais générique ne doit pas être lu comme “projet battle-ready générique”.

Le dépôt distingue maintenant clairement:

- l'initialisation de structure projet
- le seed de données de démo
- le golden slice battleable versionné

### R1 a réaligné les points de vérité bootstrap les plus trompeurs

- `trick_room` n'est plus sous-déclaré dans le seed par rapport au sous-ensemble réellement consommé
- `stealth_rock` et `spikes` ne vivent plus dans un regroupement historiquement trompeur

## Vérité produit réelle

### Golden slice battleable versionné

Le dépôt versionne une vérité produit battleable réelle:

- slice golden battleable
- save de lancement adjacente
- host Flutter lançable
- smoke tests wild et trainer

Fichiers pivots:

- `examples/playable_runtime_host/README.md`
- `examples/playable_runtime_host/golden_battle_slice/README.md`
- `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart`
- `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`

### Bootstrap projet frais générique

Un projet fraîchement initialisé n'est pas, à lui seul, la vérité produit battleable.

Le bootstrap générique:

- structure le projet
- seed le minimum nécessaire
- ne garantit pas une battleabilité générique équivalente au golden slice

### Distinction canonique à retenir

Il faut désormais distinguer explicitement:

- **golden slice battleable versionné**: preuve produit actuelle
- **bootstrap projet frais générique**: fondation projet, pas promesse battle complète

## Matrice de support par famille

| Famille | État réel PokeMap | Niveau de proximité Showdown | Notes canoniques |
|---|---|---|---|
| request model | réel mais joueur-only / slot-0 | faible structurellement, honnête localement | seam vivant, non générique |
| side / slot | réel, singles-borné avec réserves | honnête localement, loin du modèle Showdown large | vraie topologie locale |
| targeting | minimal et étroit | faible | pas de moteur de ciblage riche |
| queue / scheduling | réel, consolidé, mais encore borné | faible structurellement, honnête localement | seam clarifié, pas généralisé |
| statuses | réels pour `par/brn/psn/tox` | faible | slice honnête |
| volatiles | réels pour `protect/recharge/chargeThenStrike` | faible | slice honnête |
| field / pseudoWeather | réel pour `rain/sandstorm/trickRoom` | faible structurellement, honnête localement | slice honnête |
| hazards / side conditions | réelles pour `Stealth Rock` et `Spikes` | faible | pas de framework générique |
| switch / replacement | réels | honnête localement, loin du modèle Showdown large | vrai pipeline local |
| PP / accuracy / crit / damage | réels et bornés | honnête localement, loin de la richesse Showdown | loin de la richesse Showdown |
| runtime bridge | réel et strict | n/a produit | très bon niveau de vérité |
| runtime write-back | réel mais étroit | n/a produit | ne pas sur-vendre |
| bootstrap truth | honnête mais curaté | n/a produit | bien distinguer bootstrap et golden slice |
| host / product truth | réel | n/a produit | golden slice = vérité battleable actuelle |

## Écarts structurels principaux vs Showdown

Écarts structurants dominants:

1. `battle_session.dart` reste encore trop chargé hors scheduler pur
2. le scheduler local est désormais plus clair, mais reste trop petit pour des flows plus riches
3. les contracts requests / targeting / replacement restent trop serrés
4. les conditions moteur et les side conditions restent asymétriques
5. le runtime bridge est honnête, mais calibré pour un sous-ensemble strict

Écarts mécaniques dominants:

1. pas d'abilities
2. pas d'items
3. pas de targeting riche
4. pas de `forceSwitch` / `selfSwitch` génériques
5. pas de side conditions larges
6. pas de doubles

## Blockers classés

### Architecture

- centralisation encore réelle dans `battle_session.dart`, même si le scheduler local n'y vit plus entièrement

### Scheduling

- queue locale réelle et mieux séparée, mais pas encore assez expressive pour des flows plus riches

### Contracts

- requests / targeting / replacement trop serrés pour certaines mécaniques Showdown-like

### Runtime

- hard-fail “no bridgeable move left” honnête, plus explicite, et toujours volontairement bloquant

### Bootstrap

- les labels/support claims les plus trompeurs ont été réalignés en R1

### Documentation

- roadmap maître historique
- ancien plan battle engine
- ancien README runtime
- certains reports historiques

~~~~

### `/Users/karim/Project/pokemonProject/docs/combat/battle-roadmap-canonical-v3.1.md`

~~~~md
# Battle Roadmap Canonical v3.1

Statut: roadmap battle canonique du dépôt après `R2 — Scheduler Consolidation`

## But

Continuer à rapprocher PokeMap de Pokémon Showdown sur le périmètre singles utile,
sans faux supports, sans framework mort, et sans transformer `battle_session.dart`
en point d'absorption universel.

## Baseline canonique

Le dépôt a déjà:

- un vrai slice battle `singles-only`
- un vrai handoff runtime -> battle
- une vraie overlay branchée sur la timeline
- un vrai host battleable
- un vrai golden slice versionné
- un vrai bootstrap générique distinct de cette vérité produit

Cette roadmap ne repart pas de zéro.
Elle part d'un moteur déjà vivant mais encore trop centralisé et trop étroit sur
certains seams.

## Règles normatives

1. le code réel prime sur l'ancien récit documentaire
2. un support n'est déclaré que s'il est honnête bout à bout
3. le runtime doit rester au moins aussi strict que le moteur
4. le bootstrap doit rester honnête, pas flatteur
5. aucune étape ne doit empirer la centralisation dans `battle_session.dart`
6. aucune étape ne doit inventer un framework générique sans besoin immédiat

## Séquencement officiel

### Tronc obligatoire

1. `R0 — Truth Alignment`
2. `R1 — Battleable Slice Hardening`
3. `R2 — Scheduler Consolidation`

### Branche conditionnelle après R2

#### Si la prochaine mécanique visée est switch / replacement / targeting centric

Ordre officiel:

1. `R4 — Request / Targeting / Replacement Contract Widening`
2. `H3 — One Showdown-Leaning Micro-Slice`
3. `R3` plus tard si nécessaire

Cas typiques:

- forced switch / phazing minimal
- self switch minimal
- widening honnête des requests de remplacement

#### Si la prochaine mécanique visée est condition-centric

Ordre officiel:

1. `R3 — Condition Lifecycle Consolidation`
2. `H3 — One Showdown-Leaning Micro-Slice`
3. `R4` plus tard si nécessaire

Cas typiques:

- status/volatile plus riche
- side condition plus riche

## Définition normative des étapes

### R0 — Truth Alignment

Nature:

- documentaire
- canonique
- sans mécanique nouvelle

Sortie attendue:

- source canonique de l'état battle réel
- roadmap battle canonique propre
- recadrage ciblé des artefacts documentaires trompeurs

### R1 — Battleable Slice Hardening

Nature:

- hardening
- vérité produit

But:

- durcir le slice déjà ouvert sans l'élargir

Cible:

- fragilités explicites
- mensonges résiduels
- edge-cases honteux

### R2 — Scheduler Consolidation

Nature:

- consolidation d'un seam existant

But:

- réduire la densité de scheduling dans `battle_session.dart`
- clarifier action choisie, action planifiée, exécution et reprise

### R3 — Condition Lifecycle Consolidation

Nature:

- consolidation d'un seam existant

But:

- rendre le cycle de vie des conditions plus cohérent
- réduire l'asymétrie entre conditions moteur et side conditions déjà ouvertes

### R4 — Request / Targeting / Replacement Contract Widening

Nature:

- widening ciblé de contrats existants

But:

- élargir proprement les seams trop serrés pour certains futurs micro-slices

### H3 — One Showdown-Leaning Micro-Slice

Nature:

- enablement mécanique borné

Règle:

- un seul micro-slice
- pas avant prérequis
- pas de mécanique “cool” sans valeur structurelle

## H3: règle canonique

### H3 large maintenant

- non

### H3 micro-slice maintenant

- non comme prochaine étape officielle

### H3 micro-slice après prérequis

- oui, sous conditions

Pré-requis minimaux:

- `R0` terminé
- `R1` terminé
- `R2` terminé
- branche pertinente terminée (`R3` ou `R4`)

## Piste IA / difficulté

L'IA / difficulté ne fait pas partie du tronc principal de convergence Showdown.

Elle vit sur une piste parallèle:

- après `R1`
- idéalement après `R2`
- via un seam de policy dédié
- sans logique de difficulté codée en dur dans `battle_session.dart`

## Statut officiel après R0

`R0` est rempli par:

- `docs/combat/battle-canonical-state-v3.1.md`
- le présent document
- les notes de supersession/document truth ajoutées pendant R0

## Statut officiel après R1

`R1` est rempli par:

- le durcissement des edge-cases les plus honteux du slice battleable
- le maintien explicite du fail runtime `no bridgeable move` sans faux support
- le réalignement seed/support truth sur `trick_room`, `stealth_rock`, `spikes`

## Statut officiel après R2

`R2` est rempli par:

- la consolidation du seam scheduler déjà existant
- la séparation explicite entre action rapportée, plan de queue, consommation de queue et reprise locale
- la réduction de densité scheduler dans `battle_session.dart` sans widening de contrats ni ouverture de nouvelle mécanique

## Suite officielle après R2

Après `R2`, la suite officielle devient conditionnelle selon la prochaine mécanique visée:

- `R4` d'abord si le besoin suivant est `switch / replacement / targeting`-centric
- `R3` d'abord si le besoin suivant est `condition`-centric

~~~~

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`

~~~~dart
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
        pendingTurn: null,
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

  /// Détermine l'action de l'ennemi (IA simple).
  ///
  /// Pour ce MVP, l'IA est très simple :
  /// - Si l'ennemi peut attaquer, il attaque avec une attaque aléatoire (déterministe : première)
  /// - L'ennemi ne fuit jamais
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _chooseEnemyAction() {
    // R1 refuse toujours de rouvrir Struggle, mais supprime le vieux faux
    // fallback "Run" côté ennemi :
    // - `BattleActionRun` est une vraie fuite joueur, pas un "tour vide" ;
    // - la queue ignore déjà `Run`, donc le garder ici maquillait juste un état
    //   moteur malformé sans le traiter honnêtement ;
    // - un ennemi déjà K.O. ne doit simplement plus agir ;
    // - un ennemi vivant sans move configuré ou sans PP reste une dette visible
    //   et doit échouer explicitement.
    if (state.enemy.isFainted) {
      return const BattleActionNone();
    }
    if (state.enemy.moves.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a aucun move configuré et ne peut pas agir honnêtement.',
      );
    }
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

  List<BattleTurnEvent> _turnEventsFromStealthRock(
    Iterable<BattleStealthRockEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStealthRockEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromSpikes(
    Iterable<BattleSpikesEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnSpikesEvent.new),
    );
  }

  _ResolvedStealthRockMoveEffect? _resolveStealthRockMoveEffect({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsStealthRock || !didResolveHit) {
      return null;
    }

    if (targetSide.hasStealthRock) {
      return _ResolvedStealthRockMoveEffect(
        side: targetSide,
        events: <BattleStealthRockEvent>[
          BattleStealthRockEvent.alreadyPresent(
            side: targetSide.id,
            sourceMoveId: move.id,
          ),
        ],
      );
    }

    return _ResolvedStealthRockMoveEffect(
      side: targetSide.withStealthRock(true),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.set(
          side: targetSide.id,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  _ResolvedStealthRockEntry _resolveStealthRockEntry({
    required BattleSideState side,
  }) {
    if (!side.hasStealthRock) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final intendedDamage = resolveStealthRockEntryDamage(side.active);
    if (intendedDamage <= 0) {
      return _ResolvedStealthRockEntry(
        side: side,
        events: const <BattleStealthRockEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    final damagedActive = side.active.withDamage(actualDamage);

    return _ResolvedStealthRockEntry(
      side: side.withActive(damagedActive),
      events: <BattleStealthRockEvent>[
        BattleStealthRockEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
        ),
      ],
    );
  }

  _ResolvedSpikesMoveEffect? _resolveSpikesMoveEffect({
    required BattleMove move,
    required bool didResolveHit,
    required BattleSideState targetSide,
  }) {
    if (!move.setsSpikes || !didResolveHit) {
      return null;
    }

    if (targetSide.spikesLayers >= 3) {
      return _ResolvedSpikesMoveEffect(
        side: targetSide,
        events: <BattleSpikesEvent>[
          BattleSpikesEvent.alreadyAtMaxLayers(
            side: targetSide.id,
            layers: targetSide.spikesLayers,
          ),
        ],
      );
    }

    final nextLayers = targetSide.spikesLayers + 1;
    return _ResolvedSpikesMoveEffect(
      side: targetSide.withSpikesLayers(nextLayers),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.setLayer(
          side: targetSide.id,
          layers: nextLayers,
        ),
      ],
    );
  }

  _ResolvedSpikesEntry _resolveSpikesEntry({
    required BattleSideState side,
  }) {
    if (side.spikesLayers <= 0) {
      return _ResolvedSpikesEntry(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final intendedDamage = resolveSpikesEntryDamage(
      combatant: side.active,
      layers: side.spikesLayers,
    );
    if (intendedDamage <= 0) {
      return _ResolvedSpikesEntry(
        side: side,
        events: const <BattleSpikesEvent>[],
      );
    }

    final actualDamage = intendedDamage > side.active.currentHp
        ? side.active.currentHp
        : intendedDamage;
    final damagedActive = side.active.withDamage(actualDamage);

    return _ResolvedSpikesEntry(
      side: side.withActive(damagedActive),
      events: <BattleSpikesEvent>[
        BattleSpikesEvent.damagedOnEntry(
          side: side.id,
          targetSlot: side.activeSlotRef,
          damage: actualDamage,
          layers: side.spikesLayers,
        ),
      ],
    );
  }

  _ResolvedEntryHazards _resolveEntryHazards({
    required BattleSideState side,
  }) {
    // H2 choisit ici la plus petite composition honnête :
    // - on ne crée pas de framework de hazards ;
    // - on compose seulement les deux mécaniques réellement supportées ;
    // - l'ordre est imposé et documenté : Stealth Rock puis Spikes ;
    // - si Stealth Rock met K.O. l'entrant, Spikes ne s'applique pas.
    final stealthRockResolution = _resolveStealthRockEntry(side: side);
    final sideAfterStealthRock = stealthRockResolution.side;
    if (sideAfterStealthRock.active.isFainted) {
      return _ResolvedEntryHazards(
        side: sideAfterStealthRock,
        stealthRockEvents: stealthRockResolution.events,
        spikesEvents: const <BattleSpikesEvent>[],
      );
    }

    final spikesResolution = _resolveSpikesEntry(side: sideAfterStealthRock);
    return _ResolvedEntryHazards(
      side: spikesResolution.side,
      stealthRockEvents: stealthRockResolution.events,
      spikesEvents: spikesResolution.events,
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

class _ResolvedStealthRockMoveEffect {
  const _ResolvedStealthRockMoveEffect({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

class _ResolvedStealthRockEntry {
  const _ResolvedStealthRockEntry({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> events;
}

class _ResolvedSpikesMoveEffect {
  const _ResolvedSpikesMoveEffect({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleSpikesEvent> events;
}

class _ResolvedSpikesEntry {
  const _ResolvedSpikesEntry({
    required this.side,
    required this.events,
  });

  final BattleSideState side;
  final List<BattleSpikesEvent> events;
}

class _ResolvedEntryHazards {
  const _ResolvedEntryHazards({
    required this.side,
    required this.stealthRockEvents,
    required this.spikesEvents,
  });

  final BattleSideState side;
  final List<BattleStealthRockEvent> stealthRockEvents;
  final List<BattleSpikesEvent> spikesEvents;
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

~~~~

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`

~~~~dart
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

    final stealthRockResolution = session._resolveStealthRockMoveEffect(
      move: move,
      didResolveHit: resolution.execution?.didHit == true,
      targetSide: turn.side(_opposingSideId(step.side)),
    );
    if (stealthRockResolution != null) {
      turn.updateSide(
        _opposingSideId(step.side),
        stealthRockResolution.side,
      );
      turn.stealthRockEvents.addAll(stealthRockResolution.events);
      turn.timeline.addAll(
        session._turnEventsFromStealthRock(stealthRockResolution.events),
      );
    }

    final spikesResolution = session._resolveSpikesMoveEffect(
      move: move,
      didResolveHit: resolution.execution?.didHit == true,
      targetSide: turn.side(_opposingSideId(step.side)),
    );
    if (spikesResolution != null) {
      turn.updateSide(
        _opposingSideId(step.side),
        spikesResolution.side,
      );
      turn.spikesEvents.addAll(spikesResolution.events);
      turn.timeline
          .addAll(session._turnEventsFromSpikes(spikesResolution.events));
    }
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

    final entryHazards = session._resolveEntryHazards(
      side: turn.side(step.side),
    );
    turn.updateSide(step.side, entryHazards.side);
    turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
    turn.timeline.addAll(
      session._turnEventsFromStealthRock(entryHazards.stealthRockEvents),
    );
    turn.spikesEvents.addAll(entryHazards.spikesEvents);
    turn.timeline
        .addAll(session._turnEventsFromSpikes(entryHazards.spikesEvents));

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

  final entryHazards = session._resolveEntryHazards(
    side: turn.side(step.side),
  );
  turn.updateSide(step.side, entryHazards.side);
  turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
  turn.timeline.addAll(
    session._turnEventsFromStealthRock(entryHazards.stealthRockEvents),
  );
  turn.spikesEvents.addAll(entryHazards.spikesEvents);
  turn.timeline
      .addAll(session._turnEventsFromSpikes(entryHazards.spikesEvents));

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

~~~~

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_stealth_rock_test.dart`

~~~~dart
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

BattleMoveData _stealthRock({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'stealth_rock',
    name: 'Stealth Rock',
    power: 0,
    type: 'rock',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsStealthRock: true,
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

BattleCombatantData _combatantData({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 80,
  int? currentHp,
  BattleTypingSnapshot? typing,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 40,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    typing: typing,
    majorStatus: majorStatus,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

BattleCombatant _battleCombatant({
  required String speciesId,
  required int maxHp,
  required BattleTypingSnapshot typing,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    level: 40,
    currentHp: maxHp,
    maxHp: maxHp,
    stats: _stats(),
    typing: typing,
    moves: const <BattleMove>[],
  );
}

void main() {
  group('BattleSession H1 Stealth Rock', () {
    test('sets Stealth Rock on the opposing side with a visible event', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterTurn.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.set,
        ]),
      );
      expect(
        afterTurn.state.currentTurn!.timeline
            .whereType<BattleTurnStealthRockEvent>(),
        hasLength(1),
      );
    });

    test('does not stack Stealth Rock when it is already present', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_stealthRock()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirstSet =
          session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecondSet =
          afterFirstSet.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterSecondSet.state.enemySide.hasStealthRock, isTrue);
      expect(
        afterSecondSet.state.currentTurn!.stealthRockEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleStealthRockEventKind>[
          BattleStealthRockEventKind.alreadyPresent,
        ]),
      );
    });

    test('damages a voluntary switch-in on an affected side', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _stealthRock(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterSwitch.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.kind == BattleSwitchEventKind.switched,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.speciesId, equals('bench_player'));
      expect(afterSwitch.state.player.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'a switch-in KO from Stealth Rock keeps the pending enemy move alive '
      'after the forced replacement',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 80,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_switch',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'follow_up_switch',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            stats: _stats(speed: 30, attack: 90),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _tackle(power: 40),
            ],
          ),
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterFailedEntry =
            afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(
          afterFailedEntry.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(afterFailedEntry.state.player.isFainted, isTrue);
        expect(
          afterFailedEntry.state.currentTurn!.switchEvents.last.kind,
          equals(BattleSwitchEventKind.replacementRequired),
        );

        final resumedTurn =
            afterFailedEntry.applyChoice(const PlayerBattleChoiceSwitch(1));
        final switchEvents = resumedTurn.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);
        final damageIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnStealthRockEvent &&
              event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
        );
        final replacementSwitchIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSwitchEvent &&
              event.event.kind == BattleSwitchEventKind.switched &&
              event.event.toSpeciesId == 'follow_up_switch',
        );
        final attackIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) => event is BattleTurnExecutionEvent,
        );

        expect(resumedTurn.state.player.speciesId, equals('follow_up_switch'));
        expect(resumedTurn.state.currentTurn!.executions, isNotEmpty);
        expect(
          resumedTurn.state.currentTurn!.playerAction,
          isA<BattleActionSwitch>(),
        );
        expect(
          (resumedTurn.state.currentTurn!.playerAction as BattleActionSwitch)
              .reserveIndex,
          equals(0),
        );
        expect(
          resumedTurn.state.currentTurn!.enemyAction,
          isA<BattleActionFight>(),
        );
        expect(
          (resumedTurn.state.currentTurn!.enemyAction as BattleActionFight)
              .move
              .id,
          equals('tackle'),
        );
        expect(
          switchEvents.map((event) => event.event.kind),
          containsAllInOrder(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
            BattleSwitchEventKind.switched,
          ]),
        );
        expect(damageIndex, greaterThanOrEqualTo(0));
        expect(replacementSwitchIndex, greaterThan(damageIndex));
        expect(attackIndex, greaterThan(replacementSwitchIndex));
      },
    );

    test('damages an enemy auto-switch after a KO', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _stealthRock(),
            _tackle(power: 250),
          ],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(
              primaryType: 'fire',
              secondaryType: 'flying',
            ),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

      final damageEvent =
          afterKo.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterKo.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.enemy,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterKo.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterKo.state.enemy.currentHp, equals(40));
      expect(damageEvent.side, equals(BattleSideId.enemy));
      expect(damageEvent.damage, equals(40));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test('damages a forced player replacement when the new active enters', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 80,
          currentHp: 15,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 1),
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 90),
          moves: <BattleMoveData>[_stealthRock()],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterKo.decisionRequest, isA<BattleForcedReplacementRequest>());

      final afterReplacement =
          afterKo.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterReplacement.state.currentTurn!.stealthRockEvents.singleWhere(
        (event) => event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );
      final timeline = afterReplacement.state.currentTurn!.timeline;
      final switchIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnSwitchEvent &&
            event.event.side == BattleSideId.player,
      );
      final damageIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnStealthRockEvent &&
            event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
      );

      expect(afterReplacement.state.player.speciesId, equals('bench_player'));
      expect(afterReplacement.state.player.currentHp, equals(70));
      expect(afterReplacement.state.currentTurn!.enemyAction,
          isA<BattleActionNone>());
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(damageIndex, greaterThan(switchIndex));
    });

    test(
      'waits until the enemy auto-switch chain settles before asking the '
      'player to replace after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'stable_enemy_backup',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        final switchEvents = afterDoubleKo.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);

        expect(
          afterDoubleKo.decisionRequest,
          isA<BattleForcedReplacementRequest>(),
        );
        expect(
          switchEvents.map((event) => event.event.kind).toList(growable: false),
          equals(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
          ]),
        );
        expect(
          switchEvents[0].event.toSpeciesId,
          equals('fragile_enemy_backup'),
        );
        expect(
          switchEvents[1].event.toSpeciesId,
          equals('stable_enemy_backup'),
        );
        expect(
          switchEvents.last.event.side,
          equals(BattleSideId.player),
        );
      },
    );

    test(
      'does not emit a bogus player replacement when the last enemy reserve '
      'dies to Stealth Rock after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 5,
              typing: const BattleTypingSnapshot(
                primaryType: 'fire',
                secondaryType: 'flying',
              ),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        expect(afterDoubleKo.state.isFinished, isTrue);
        expect(
          afterDoubleKo.state.outcome?.type,
          equals(BattleOutcomeType.victory),
        );
        expect(
          afterDoubleKo.state.currentTurn!.switchEvents
              .where(
                (event) =>
                    event.kind == BattleSwitchEventKind.replacementRequired,
              )
              .toList(growable: false),
          isEmpty,
        );
      },
    );

    test(
        'resolves Stealth Rock damage from Rock effectiveness with a minimum of one',
        () {
      final quadrupleWeak = _battleCombatant(
        speciesId: 'charizard_like',
        maxHp: 80,
        typing: const BattleTypingSnapshot(
          primaryType: 'fire',
          secondaryType: 'flying',
        ),
      );
      final quarterResist = _battleCombatant(
        speciesId: 'resist_like',
        maxHp: 20,
        typing: const BattleTypingSnapshot(
          primaryType: 'fighting',
          secondaryType: 'ground',
        ),
      );

      expect(resolveStealthRockEntryDamage(quadrupleWeak), equals(40));
      expect(resolveStealthRockEntryDamage(quarterResist), equals(1));
    });
  });
}

~~~~

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_spikes_test.dart`

~~~~dart
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

BattleMoveData _stealthRock({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'stealth_rock',
    name: 'Stealth Rock',
    power: 0,
    type: 'rock',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsStealthRock: true,
  );
}

BattleMoveData _spikes({
  int pp = 20,
  int currentPp = 20,
}) {
  return BattleMoveData(
    id: 'spikes',
    name: 'Spikes',
    power: 0,
    type: 'ground',
    category: BattleMoveCategory.status,
    target: BattleMoveTarget.opponentSide,
    accuracy: BattleMoveAccuracy.alwaysHits(),
    pp: pp,
    currentPp: currentPp,
    setsSpikes: true,
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

BattleCombatantData _combatantData({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 80,
  int? currentHp,
  BattleTypingSnapshot? typing,
  BattleStatsSnapshot? stats,
  BattleMajorStatusState? majorStatus,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 40,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    typing: typing,
    majorStatus: majorStatus,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  List<BattleCombatantData> enemyReserve = const <BattleCombatantData>[],
  bool isTrainerBattle = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      enemyReservePokemon: enemyReserve,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

void main() {
  group('BattleSession H2 Spikes', () {
    test('sets the first Spikes layer on the opposing side', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemySide.spikesLayers, equals(1));
      expect(
        afterTurn.state.currentTurn!.spikesEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleSpikesEventKind>[BattleSpikesEventKind.setLayer]),
      );
      expect(
          afterTurn.state.currentTurn!.spikesEvents.single.layers, equals(1));
    });

    test('raises Spikes from one layer to two layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterSecond.state.enemySide.spikesLayers, equals(2));
      expect(
        afterSecond.state.currentTurn!.spikesEvents.single.layers,
        equals(2),
      );
    });

    test('raises Spikes from two layers to three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterThird.state.enemySide.spikesLayers, equals(3));
      expect(
          afterThird.state.currentTurn!.spikesEvents.single.layers, equals(3));
    });

    test('does not stack Spikes past three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[_spikes()],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));
      final afterFourth =
          afterThird.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterFourth.state.enemySide.spikesLayers, equals(3));
      expect(
        afterFourth.state.currentTurn!.spikesEvents.single.kind,
        equals(BattleSpikesEventKind.alreadyAtMaxLayers),
      );
      expect(
        afterFourth.state.currentTurn!.spikesEvents.single.layers,
        equals(3),
      );
    });

    test('damages a grounded voluntary switch-in with one layer', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(70));
      expect(damageEvent.damage, equals(10));
      expect(damageEvent.layers, equals(1));
    });

    test('damages a grounded voluntary switch-in with two layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 2, currentPp: 2),
            _waitingMove(),
          ],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterSecond.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(67));
      expect(damageEvent.damage, equals(13));
      expect(damageEvent.layers, equals(2));
    });

    test('damages a grounded voluntary switch-in with three layers', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 3, currentPp: 3),
            _waitingMove(),
          ],
        ),
      );

      final afterFirst = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSecond =
          afterFirst.applyChoice(const PlayerBattleChoiceFight(0));
      final afterThird =
          afterSecond.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterThird.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterSwitch.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterSwitch.state.player.currentHp, equals(60));
      expect(damageEvent.damage, equals(20));
      expect(damageEvent.layers, equals(3));
    });

    test('does not damage a Flying-type switch-in', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 60,
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'flying_bench',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(
              primaryType: 'water',
              secondaryType: 'flying',
            ),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterSwitch =
          afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

      expect(afterSwitch.state.player.currentHp, equals(80));
      expect(afterSwitch.state.currentTurn!.spikesEvents, isEmpty);
    });

    test('damages an enemy auto-switch after a KO', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          stats: _stats(speed: 90, attack: 100),
          moves: <BattleMoveData>[
            _spikes(),
            _tackle(power: 250),
          ],
        ),
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          maxHp: 40,
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        enemyReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

      final damageEvent = afterKo.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterKo.state.enemy.speciesId, equals('bench_enemy'));
      expect(afterKo.state.enemy.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.enemy));
      expect(damageEvent.damage, equals(10));
    });

    test('damages a forced player replacement when the new active enters', () {
      final session = _session(
        player: _combatantData(
          speciesId: 'lead_player',
          lineupIndex: 0,
          maxHp: 80,
          currentHp: 15,
          majorStatus: const BattleMajorStatusState.tox(toxicCounter: 1),
          stats: _stats(speed: 20),
          moves: <BattleMoveData>[_waitingMove()],
        ),
        playerReserve: <BattleCombatantData>[
          _combatantData(
            speciesId: 'bench_player',
            lineupIndex: 1,
            maxHp: 80,
            typing: const BattleTypingSnapshot(primaryType: 'water'),
            moves: <BattleMoveData>[_waitingMove()],
          ),
        ],
        enemy: _combatantData(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
          stats: _stats(speed: 90),
          moves: <BattleMoveData>[
            _spikes(pp: 1, currentPp: 1),
            _waitingMove(),
          ],
        ),
      );

      final afterHazard = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterKo = afterHazard.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterKo.decisionRequest, isA<BattleForcedReplacementRequest>());

      final afterReplacement =
          afterKo.applyChoice(const PlayerBattleChoiceSwitch(0));

      final damageEvent =
          afterReplacement.state.currentTurn!.spikesEvents.singleWhere(
        (event) => event.kind == BattleSpikesEventKind.damagedOnEntry,
      );

      expect(afterReplacement.state.player.currentHp, equals(70));
      expect(damageEvent.side, equals(BattleSideId.player));
      expect(damageEvent.damage, equals(10));
      expect(afterReplacement.state.currentTurn!.enemyAction,
          isA<BattleActionNone>());
    });

    test(
      'resolves Stealth Rock before Spikes on entry and stops on Stealth Rock KO',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 60,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_grounded_bench',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 10,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'healthy_grounded_bench',
              lineupIndex: 2,
              maxHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _stealthRock(pp: 1, currentPp: 1),
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
        );

        final afterStealthRock =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterSpikes =
            afterStealthRock.applyChoice(const PlayerBattleChoiceFight(0));
        final afterSwitch =
            afterSpikes.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(afterSwitch.state.player.isFainted, isTrue);
        expect(
          afterSwitch.state.currentTurn!.spikesEvents
              .where(
                  (event) => event.kind == BattleSpikesEventKind.damagedOnEntry)
              .toList(growable: false),
          isEmpty,
        );

        final resumedTurn =
            afterSwitch.applyChoice(const PlayerBattleChoiceSwitch(1));
        final srDamageIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnStealthRockEvent &&
              event.event.kind == BattleStealthRockEventKind.damagedOnEntry,
        );
        final spikesDamageIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSpikesEvent &&
              event.event.kind == BattleSpikesEventKind.damagedOnEntry,
        );

        expect(resumedTurn.state.player.currentHp, equals(60));
        expect(srDamageIndex, greaterThanOrEqualTo(0));
        expect(spikesDamageIndex, greaterThan(srDamageIndex));
      },
    );

    test(
      'a switch-in KO from Spikes keeps the pending enemy move alive after '
      'the forced replacement',
      () {
        final session = _session(
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 80,
            moves: <BattleMoveData>[_waitingMove()],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_switch',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'follow_up_switch',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            stats: _stats(speed: 30, attack: 90),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _tackle(power: 40),
            ],
          ),
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterFailedEntry =
            afterHazard.applyChoice(const PlayerBattleChoiceSwitch(0));

        expect(afterFailedEntry.decisionRequest,
            isA<BattleForcedReplacementRequest>());
        expect(afterFailedEntry.state.player.isFainted, isTrue);

        final resumedTurn =
            afterFailedEntry.applyChoice(const PlayerBattleChoiceSwitch(1));
        final damageIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSpikesEvent &&
              event.event.kind == BattleSpikesEventKind.damagedOnEntry,
        );
        final replacementSwitchIndex =
            resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) =>
              event is BattleTurnSwitchEvent &&
              event.event.kind == BattleSwitchEventKind.switched &&
              event.event.toSpeciesId == 'follow_up_switch',
        );
        final attackIndex = resumedTurn.state.currentTurn!.timeline.indexWhere(
          (event) => event is BattleTurnExecutionEvent,
        );

        expect(resumedTurn.state.player.speciesId, equals('follow_up_switch'));
        expect(
          resumedTurn.state.currentTurn!.playerAction,
          isA<BattleActionSwitch>(),
        );
        expect(
          (resumedTurn.state.currentTurn!.playerAction as BattleActionSwitch)
              .reserveIndex,
          equals(0),
        );
        expect(
          resumedTurn.state.currentTurn!.enemyAction,
          isA<BattleActionFight>(),
        );
        expect(
          (resumedTurn.state.currentTurn!.enemyAction as BattleActionFight)
              .move
              .id,
          equals('tackle'),
        );
        expect(replacementSwitchIndex, greaterThan(damageIndex));
        expect(attackIndex, greaterThan(replacementSwitchIndex));
      },
    );

    test(
      'waits until the enemy auto-switch chain settles before asking the '
      'player to replace after a double KO on a Spikes side',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
            _combatantData(
              speciesId: 'stable_enemy_backup',
              lineupIndex: 2,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        final switchEvents = afterDoubleKo.state.currentTurn!.timeline
            .whereType<BattleTurnSwitchEvent>()
            .toList(growable: false);

        expect(afterDoubleKo.decisionRequest,
            isA<BattleForcedReplacementRequest>());
        expect(
          switchEvents.map((event) => event.event.kind).toList(growable: false),
          equals(<BattleSwitchEventKind>[
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.switched,
            BattleSwitchEventKind.replacementRequired,
          ]),
        );
        expect(
            switchEvents[0].event.toSpeciesId, equals('fragile_enemy_backup'));
        expect(
            switchEvents[1].event.toSpeciesId, equals('stable_enemy_backup'));
        expect(switchEvents.last.event.side, equals(BattleSideId.player));
      },
    );

    test(
      'does not emit a bogus player replacement when the last enemy reserve '
      'dies to Spikes after a double KO',
      () {
        final session = _session(
          isTrainerBattle: true,
          player: _combatantData(
            speciesId: 'lead_player',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[
              _spikes(pp: 1, currentPp: 1),
              _waitingMove(),
            ],
          ),
          playerReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'player_backup',
              lineupIndex: 1,
              maxHp: 80,
              currentHp: 80,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
          enemy: _combatantData(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
            maxHp: 10,
            currentHp: 2,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_waitingMove()],
          ),
          enemyReserve: <BattleCombatantData>[
            _combatantData(
              speciesId: 'fragile_enemy_backup',
              lineupIndex: 1,
              maxHp: 10,
              currentHp: 1,
              typing: const BattleTypingSnapshot(primaryType: 'water'),
              moves: <BattleMoveData>[_waitingMove()],
            ),
          ],
        );

        final afterHazard =
            session.applyChoice(const PlayerBattleChoiceFight(0));
        final afterDoubleKo =
            afterHazard.applyChoice(const PlayerBattleChoiceFight(1));

        expect(afterDoubleKo.state.isFinished, isTrue);
        expect(
          afterDoubleKo.state.outcome?.type,
          equals(BattleOutcomeType.victory),
        );
        expect(
          afterDoubleKo.state.currentTurn!.switchEvents
              .where(
                (event) =>
                    event.kind == BattleSwitchEventKind.replacementRequired,
              )
              .toList(growable: false),
          isEmpty,
        );
      },
    );
  });
}

~~~~

