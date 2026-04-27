# Phase F — Action Queue Plus Riche Report

## 1. Résumé exécutif honnête

Verdict global : **Phase F est réellement réussie**.

Ce qui a réellement changé :
- `packages/map_battle/lib/src/battle_queue.dart` introduit une vraie queue locale de tour avec une taxonomie explicite de steps réellement consommée par le moteur.
- `packages/map_battle/lib/src/battle_session.dart` ne dépend plus seulement d'un pipeline figé pour enchaîner les grandes étapes du tour ; il construit, consomme et enrichit maintenant une vraie queue.
- la fin de tour et les checks post-résolution sont désormais des étapes explicites du scheduling.
- l'auto-remplacement ennemi, le marqueur de remplacement requis joueur, et après review le remplacement forcé joueur inter-tour passent maintenant par le seam de queue au lieu d'être appendés à côté du tour.
- les tests battle durcissent la chronologie observable sur switch, recharge, fin de tour et double K.O.

Ce qui n'a volontairement pas changé :
- pas de `selfSwitch`.
- pas de `forceSwitch`.
- pas de hazards.
- pas de side conditions actives.
- pas de slot conditions actives.
- pas de doubles.
- pas d'abilities/items.
- pas d'event bus générique.
- pas d'expansion large des contrats Phase G.
- pas de modification du runtime de production.

Pourquoi c'est bien Phase F et pas une Phase G/H déguisée :
- le gain porte sur le **scheduling réel** du tour déjà supporté, pas sur l'ouverture de nouvelles mécaniques.
- la queue reste petite, locale, internal-only et immédiatement consommée.
- `BattleConditionEngine` n'est pas devenu une queue ; `BattleSession` reste l'orchestrateur.
- aucun nouveau modèle générique de commandes/callbacks/targets n'a été ouvert.

Réponse brève aux questions finales du prompt :
- la queue introduite est réellement canonique et consommée pour le flow de tour supporté.
- oui, c'est une vraie Phase F.
- oui, le moteur dépend désormais moins d'un pipeline figé.
- oui, la chronologie observable reste honnête.
- oui, le lot reste strictement dans le scope F.
- oui, le prochain chantier logique redevient Phase G.
- F débloque un scheduling plus honnête et plus extensible pour les futurs cas plus complexes.
- F ne débloque toujours pas `selfSwitch`, `forceSwitch`, hazards, targeting riche, doubles, ni une taxonomie Showdown-like complète.

## 2. Verdict global

Verdict : **accepté**.

Ce lot n'est ni un renommage, ni un faux wrapper. La queue est :
- explicite,
- réellement exécutée en prod dans `BattleSession`,
- enrichie dynamiquement,
- responsable de la fin de tour et des suites post-résolution déjà supportées.

Le reviewer séparé a d'abord trouvé un vrai trou : le remplacement forcé joueur inter-tour restait encore sur un chemin manuel hors queue. Ce finding a été confirmé, corrigé, puis reverrouillé par une seconde review sans finding résiduel concret.

## 3. Pré-gates exécutés + résultats

### Confirmé par exécution
Pré-gates Git read-only exécutés avant modification :
- `git -C /Users/karim/Project/pokemonProject status --short --untracked-files=all`
- `git -C /Users/karim/Project/pokemonProject diff --stat`
- `git -C /Users/karim/Project/pokemonProject ls-files --others --exclude-standard`

### État initial interprété honnêtement
- le worktree était propre pour ce lot au tout début.
- aucune écriture Git n'a été nécessaire.
- le périmètre utile confirmé vivait dans `packages/map_battle`.
- le runtime n'avait besoin que d'une vérification de non-régression, pas d'une migration.

## 4. Méthode réelle utilisée

### Audit
Confirmé par lecture de code :
- lecture des reports Phase A à E demandés par le prompt.
- lecture de `battle_session.dart`, `battle_condition_engine.dart`, `battle_decision.dart`, `battle_state.dart`, `battle_switch.dart`, `battle_resolution.dart`, `battle_topology.dart`, `battle_action.dart`.
- lecture ciblée de tests battle (`battle_switch_test.dart`, `battle_field_test.dart`, `battle_volatiles_test.dart`, `battle_session_flow_test.dart`, `battle_decision_request_test.dart`).
- lecture ciblée du runtime (`battle_overlay_component.dart`) et du smoke test Phase A.

### Design
Confirmé par audit + sub-agents :
- choix d'une queue interne locale dans `battle_queue.dart`.
- refus d'un faux event bus, d'un command model générique, d'un système de callbacks, d'une queue publique ou d'une taxonomie de targeting.
- conservation de `Run` / `Capture` hors queue comme issues terminales hors résolution normale.

### Implémentation
Confirmé par lecture de code :
- création de `BattleTurnQueue` et de steps explicites.
- migration de `_resolveTurn` vers construction + consommation d'une queue.
- insertion dynamique de fin de tour et de checks post-résolution.
- correction après review du remplacement forcé joueur pour qu'il passe lui aussi par la queue.

### Validation
Confirmé par exécution :
- TDD rouge initial sur `battle_queue_test.dart`.
- tests battle ciblés.
- analyze battle ciblé puis complet.
- `dart test` complet `packages/map_battle`.
- analyze runtime ciblé.
- tests runtime ciblés + smoke Phase A.

### Review
Confirmé par exécution :
- sub-agent audit/design battle-core : `Turing`.
- sub-agent scope creep : `Lagrange`.
- reviewer final séparé : `Poincare`.

## 5. Audit réel avant code

### Où le pipeline restait trop figé
Confirmé par lecture de code :
- `BattleSession.applyChoice()` restait encore l'orchestrateur séquentiel principal du tour.
- `_resolveTurn(...)` résolvait encore les deux actions dans une boucle séquentielle hardcodée puis exécutait ensuite la fin de tour directement.
- la logique post-tour de remplacements vivait encore dans `_resolvePostTurnSwitchState(...)`, donc hors du cœur du tour résolu.
- la chronologie était honnête via `BattleTurnResult.timeline`, mais le **scheduler** ne l'était pas encore structurellement.

### Où la queue apportait un vrai gain
Confirmé par lecture de code et ensuite par implémentation :
- rendre explicite la frontière entre phase d'actions, fin de tour et checks post-résolution.
- rendre explicites les insertions dynamiques déjà nécessaires :
  - fin de tour,
  - checks post-résolution,
  - auto-switch ennemi,
  - replacement-required joueur,
  - replacement forcé joueur après review.
- sortir la séquence "actions puis append post-traité" pour faire du scheduling un vrai seam local.

### Faux progrès explicitement écartés
Confirmé par audit/design :
- une queue purement décorative qui ne ferait que wraper la boucle existante.
- une micro-queue de sous-événements de dégâts, crits, hit check, etc.
- un event bus générique façon Showdown.
- une queue publique exposée au runtime.
- une expansion des contrats de move/combatant/field/volatile hors besoin de Phase F.

### Ce qui reste hors scope après F
Confirmé par lecture de code + inférence raisonnable :
- `selfSwitch` / `forceSwitch`.
- queue multi-slot ou doubles.
- scheduling d'abilities/items.
- hazards / side conditions.
- targeting riche.
- un modèle de commandes généraliste.

## 6. Design retenu

### Structure exacte
Confirmé par lecture de code :
- nouveau fichier `packages/map_battle/lib/src/battle_queue.dart`.
- nouveau type `BattleTurnQueue`.
- taxonomie des steps :
  - `BattleQueueActionStep`
  - `BattleQueueEndOfTurnStep`
  - `BattleQueuePostTurnChecksStep`
  - `BattleQueueAutoSwitchStep`
  - `BattleQueueReplacementRequiredStep`
- helper borné `isBattleQueueManagedAction(...)`.
- contexte mutable local `_QueuedTurnContext` dans `battle_session.dart` pour la consommation d'une queue pendant `_resolveTurn`.

### Pourquoi ce design
Confirmé par audit + review :
- assez petit pour rester Phase F.
- assez réel pour remplacer la source de vérité du scheduling du tour.
- assez contraint pour empêcher le scope creep vers G/H.
- assez vivant pour être immédiatement consommé dans la prod, pas juste dans les tests.

### Ce qui a été refusé
Confirmé par audit/design :
- queue publique exportée par `map_battle.dart`.
- callbacks dynamiques.
- registry futuriste de steps.
- sous-étapes de micro-résolution à la Showdown.
- champ générique `payload` / `reason` partout.
- refonte runtime opportuniste.

## 7. Critique explicite du prompt

### Ce qui était juste
- le prompt insistait correctement sur le fait qu'une vraie Phase F devait remplacer un pipeline figé, pas juste le renommer.
- le prompt était juste sur le besoin d'insertions dynamiques explicites.
- le prompt était juste sur le fait qu'il fallait garder `BattleTurnResult.timeline` honnête.
- le prompt était juste sur le danger d'une queue décorative.

### Ce qui était discutable
- la formulation "la queue doit couvrir remplacements post-KO" pouvait être interprétée de deux façons :
  - seulement les suites post-turn de `_resolveTurn`,
  - ou aussi le remplacement forcé joueur inter-tour.
  La review a montré que la seconde lecture était la bonne si on veut une queue réellement canonique dans le scope supporté.

### Ce qui aurait été dangereux si suivi aveuglément
- faire passer `Run` / `Capture` par la queue pour "uniformiser" aurait brouillé une frontière métier utile sans gain réel Phase F.
- transformer `BattleAction` en proto-command model générique aurait ouvert Phase G/H en douce.
- créer une queue publique parce que le runtime affiche une timeline aurait été une erreur de blast radius.

### Recadrage retenu
- queue canonique pour le **flow de résolution supporté**.
- `Run` / `Capture` restent hors queue par design.
- le remplacement forcé joueur est bien rentré dans la queue après review, car il fait partie du flow supporté du moteur singles actuel.

## 8. Périmètre inclus / exclu

### Inclus
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_queue_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`
- `packages/map_battle/test/battle_field_test.dart`
- `packages/map_battle/test/battle_volatiles_test.dart`
- report final sous `reports/`

### Exclus volontairement
- `packages/map_runtime/**` en production
- `examples/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- nouvelles mécaniques battle
- queue publique / runtime-facing
- expansion de contrats Phase G
- mécaniques riches Phase H

### Justification du non-changement runtime
Confirmé par lecture de code + exécution :
- le runtime consomme toujours `BattleTurnResult.timeline` et les requests existantes.
- aucun nouveau type Phase F n'a eu besoin d'être exposé au runtime.
- les tests runtime et le smoke Phase A sont restés verts sans modification.

## 9. Plan local retenu

1. auditer le pipeline figé restant dans `BattleSession`.
2. demander deux audits séparés sur le design et le scope creep.
3. poser un test rouge sur le seam de queue.
4. introduire une vraie queue interne et la brancher dans `_resolveTurn`.
5. migrer fin de tour et checks post-résolution dans cette queue.
6. durcir les tests de chronologie.
7. faire la review séparée.
8. corriger le finding valide du reviewer.
9. rerun analyze/tests/smoke.
10. produire le report final ultra-complet.

## 10. Justification fichier par fichier

### `packages/map_battle/lib/src/battle_queue.dart`
Créé pour porter le seam Phase F réel : queue, taxonomie des steps, validation locale des attachments side/slot et garde-fous sur les actions admissibles.

### `packages/map_battle/lib/src/battle_session.dart`
Modifié pour :
- consommer la queue comme source de vérité du scheduling du tour ;
- insérer explicitement fin de tour et checks post-résolution ;
- consommer les auto-switch/replacement-required déjà supportés ;
- faire passer aussi le remplacement forcé joueur par la queue après review.

### `packages/map_battle/test/battle_queue_test.dart`
Créé pour prouver :
- qu'une vraie queue existe ;
- qu'elle est FIFO ;
- qu'elle accepte des insertions post-turn ;
- qu'elle rejette les attachements incohérents ;
- qu'elle rejette les pseudo-actions hors scope.

### `packages/map_battle/test/battle_switch_test.dart`
Durci pour prouver que la chronologie explicite reste honnête sur :
- switch volontaire avant attaque adverse ;
- replacement forcé joueur inter-tour ;
- double K.O. avec auto-switch ennemi puis replacement-required joueur.

### `packages/map_battle/test/battle_field_test.dart`
Durci pour prouver que le résiduel de fin de tour arrive bien après les actions du tour dans la timeline.

### `packages/map_battle/test/battle_volatiles_test.dart`
Durci pour prouver que la continuation forcée de recharge est explicitement séquencée avant l'action adverse dans la timeline quand c'est l'ordre réel du tour.

## 11. Classification des blockers réellement adressés

### Blockers structurels adressés
Confirmé par lecture de code :
- disparition du couplage fort entre "ordre du tour" et "pipeline séquentiel fixe".
- disparition du post-traitement de remplacements hors scheduler principal.
- apparition d'un vrai point d'insertion pour la fin de tour et les suites de tour.

### Blockers volontairement non adressés
Confirmé par lecture de code :
- taxonomie plus riche de commandes.
- action queue multi-slot.
- mécaniques side-based.
- `selfSwitch` / `forceSwitch`.
- hooks/events plus larges.
- expansion de contrats battle.

## 12. Commandes réellement exécutées

### Git read-only
- `git -C /Users/karim/Project/pokemonProject status --short --untracked-files=all`
- `git -C /Users/karim/Project/pokemonProject diff --stat`
- `git -C /Users/karim/Project/pokemonProject ls-files --others --exclude-standard`
- `git -C /Users/karim/Project/pokemonProject diff -- /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart /Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_queue_test.dart /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_switch_test.dart /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_field_test.dart /Users/karim/Project/pokemonProject/packages/map_battle/test/battle_volatiles_test.dart`

### Audit lecture
- `sed -n ...` sur les reports Phase A à E
- `sed -n ...` sur `battle_session.dart`, `battle_condition_engine.dart`, `battle_action.dart`, `battle_state.dart`, `battle_switch.dart`, `battle_resolution.dart`, `battle_topology.dart`
- `rg -n ...` sur `battle_session.dart` et `packages/map_battle/test`
- `sed -n ...` / `cat` sur les tests battle ciblés
- `sed -n ...` sur `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

### TDD / format / validate
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_queue_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_session.dart lib/src/battle_queue.dart test/battle_queue_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart format lib/src/battle_queue.dart lib/src/battle_session.dart test/battle_queue_test.dart test/battle_switch_test.dart test/battle_field_test.dart test/battle_volatiles_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test test/battle_queue_test.dart test/battle_switch_test.dart test/battle_field_test.dart test/battle_volatiles_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd /Users/karim/Project/pokemonProject/packages/map_battle && /opt/homebrew/bin/dart test`
- `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub test/battle_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`
- `cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test test/battle_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart`

### Review/sub-agents
- sub-agent battle-core audit/design
- sub-agent scope creep
- reviewer final

## 13. Résultats réels format / analyze / tests / smoke

### Confirmé par exécution
`dart format` : vert sur tous les fichiers touchés.

`packages/map_battle` analyze ciblé : vert.

`packages/map_battle` analyze complet : vert.

`packages/map_battle` tests ciblés : verts.

`packages/map_battle` tests complets : verts.

`packages/map_runtime` analyze ciblé : vert.

`packages/map_runtime` tests ciblés : verts.

Smoke Phase A golden slice : vert via `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart`.

### Détail utile
- `dart test` complet `packages/map_battle` : `All tests passed!`
- `flutter test test/battle_overlay_component_test.dart test/phase_a_golden_battle_slice_smoke_test.dart` : `All tests passed!`
- `flutter analyze --no-pub ...` ciblé : `No issues found!`

## 14. Incidents rencontrés

### Incident 1 — lock Flutter
Confirmé par exécution :
- un lancement parallèle `flutter analyze` / `flutter test` a rencontré le lock de startup Flutter.
- résolution : rerun séquentiel propre.
- impact : aucun sur le code, seulement sur la séquence de validation.

### Incident 2 — finding reviewer valide
Confirmé par review + exécution :
- le reviewer a trouvé que `_applyForcedPlayerReplacement` restait hors queue.
- le finding a été vérifié comme techniquement correct.
- correction appliquée : le remplacement forcé joueur passe maintenant aussi par `BattleTurnQueue`.

### Incident 3 — régression locale de vérité `wasForced`
Confirmé par exécution :
- après cette correction, un test a cassé car le switch inter-tour perdait `wasForced == true`.
- cause : le nouveau passage par `BattleQueueActionStep` traitait encore tous les `BattleActionSwitch` comme volontaires.
- correction : ajout d'un flag local `wasForced` sur `BattleQueueActionStep`, strictement borné à la vérité du switch.

## 15. Décisions retenues / rejetées

### Retenues
- queue interne non exportée.
- steps explicites et peu nombreux.
- construction initiale de la queue à partir de l'ordre résolu.
- insertion dynamique de fin de tour et de checks post-résolution.
- insertion dynamique d'auto-switch et de replacement-required.
- correction du remplacement forcé joueur pour le faire passer aussi par la queue.

### Rejetées
- queue publique.
- steps micro-granulaires pour hit/crit/dégâts.
- refonte du runtime.
- intégration de `Run` / `Capture` dans la queue.
- command model générique.
- ouverture d'une taxonomie plus riche que nécessaire.

## 16. Retour des sub-agents

### `Turing` — audit/design battle-core
Apport principal :
- a confirmé les points encore hardcodés dans `BattleSession`.
- a recommandé une taxonomie minimale de queue : action, end-of-turn, post-turn checks, auto-switch, replacement-required.
- a explicitement déconseillé une micro-queue de sous-événements de move.

Retenu :
- taxonomie minimale de steps.
- dynamique d'insertion explicite.
- refus d'utiliser la queue pour la micro-résolution d'un move.

Rejeté :
- rien de majeur ; l'audit était aligné avec le besoin réel.

### `Lagrange` — audit scope creep
Apport principal :
- a listé les red lines exactes de Phase G/H à ne pas franchir.
- a mis en garde contre les faux types génériques et les hooks/callbacks opportunistes.
- a rappelé que la queue devait rester interne et ne pas devenir un contrat runtime/public.

Retenu :
- queue internal-only.
- refus de généraliser `BattleAction`.
- refus des faux champs `reason/target/phase/callback` partout.

Rejeté :
- rien de majeur ; la garde de scope était correcte et utile.

## 17. Retour du reviewer séparé

### Premier retour
Le reviewer `Poincare` a trouvé un vrai bug de périmètre :
- le remplacement forcé joueur inter-tour restait encore sur un chemin manuel hors queue ;
- la queue n'était donc pas encore canonique pour tout le flow supporté du moteur.

### Évaluation technique
Confirmé par lecture de code :
- finding valide.
- il s'agissait bien d'un flow déjà supporté et pas d'une feature hors scope.
- ne pas le corriger aurait laissé deux sources de vérité de scheduling pour les remplacements.

### Second retour après correction
Le reviewer a ensuite rerelé le diff et a répondu :
- **no findings**.
- la queue est désormais canonique pour :
  - les actions ordonnées,
  - le forced continue / recharge,
  - la fin de tour,
  - les checks post-résolution,
  - l'auto-switch ennemi,
  - le remplacement forcé joueur.

### Risques résiduels signalés par le reviewer
- `Run` / `Capture` restent hors queue par design.
- le flag `wasForced` sur `BattleQueueActionStep` doit rester un seam local de vérité du switch, pas devenir un proto-command model généraliste.

## 18. Corrections appliquées après review

1. `_applyForcedPlayerReplacement(...)` passe maintenant par `BattleTurnQueue`.
2. le chemin manuel qui fabriquait directement `BattleTurnResult` pour ce flow a disparu.
3. `BattleQueueActionStep` porte maintenant `wasForced` pour préserver la vérité du switch inter-tour sans ouvrir une nouvelle taxonomie inutile.
4. `battle_switch_test.dart` a été durci pour vérifier qu'un remplacement forcé inter-tour reste un tour de switch pur, sans fin de tour artificielle.

## 19. Autocritique finale

### Ce qui est vraiment mieux
- le scheduling du tour n'est plus juste une suite d'if et d'append post-traités.
- la fin de tour et les suites post-résolution ont maintenant un lieu de vie structurel.
- la queue est petite mais réelle.

### Ce que F ne fait toujours pas
- elle ne résout pas les besoins d'une taxonomie plus riche de commandes.
- elle ne résout pas `selfSwitch` / `forceSwitch` / hazards / targeting riche.
- elle ne fait pas de `BattleTurnResult.timeline` une queue d'exécution ; la timeline reste une trace, ce qui est le bon choix ici.

### Risques restants
- le seam `wasForced` sur `BattleQueueActionStep` est juste ce qu'il faut aujourd'hui, mais il faudra le garder local et ne pas l'étendre en pseudo-framework.
- `_resolveTurnOrder(...)` reste encore un calcul dédié à deux côtés/singles ; c'est cohérent avec le scope, mais pas réutilisable tel quel pour des futurs lots plus larges.

### Réponse franche à la question finale
- **Phase F est-elle réellement réussie ?** Oui.
- **Qu'est-ce qu'elle débloque exactement pour Phase G ?** Un scheduler canonique, explicite et testable sur lequel des contrats plus riches pourront ensuite s'appuyer sans rajouter un second pipeline caché.
- **Qu'est-ce qu'elle ne débloque PAS encore ?** Les mécaniques riches de H, les flows plus complexes de switch forcé, les side/slot conditions, les abilities/items, les doubles.
- **Le prochain lot logique est-il bien Phase G ?** Oui, à condition de rester fidèle à la roadmap et de traiter G comme expansion de contrats réellement tirée par les besoins, pas comme inflation abstraite.

## 20. État git final utile

### `git status --short --untracked-files=all`
```text
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_field_test.dart
 M packages/map_battle/test/battle_switch_test.dart
 M packages/map_battle/test/battle_volatiles_test.dart
?? packages/map_battle/lib/src/battle_queue.dart
?? packages/map_battle/test/battle_queue_test.dart
?? reports/phase-f-action-queue-report.md
```

### `git diff --stat`
```text
 packages/map_battle/lib/src/battle_session.dart    | 658 ++++++++++++---------
 packages/map_battle/test/battle_field_test.dart    |  12 +
 packages/map_battle/test/battle_switch_test.dart   |  34 ++
 .../map_battle/test/battle_volatiles_test.dart     |  13 +
 4 files changed, 431 insertions(+), 286 deletions(-)
```

Note honnête :
- `git diff --stat` ne montre pas les fichiers non suivis.
- les créations réelles sont visibles via `git status` et `git ls-files --others --exclude-standard`.

### `git ls-files --others --exclude-standard`
```text
packages/map_battle/lib/src/battle_queue.dart
packages/map_battle/test/battle_queue_test.dart
reports/phase-f-action-queue-report.md
```

## 21. Checklist finale

- [x] audit réel fait avant code
- [x] design Phase F borné choisi sans variantes concurrentes
- [x] vraie queue interne introduite
- [x] queue réellement consommée par `BattleSession`
- [x] insertions dynamiques explicites introduites
- [x] fin de tour explicitement séquencée
- [x] remplacements post-KO explicitement séquencés
- [x] remplacement forcé joueur intégré à la queue après review
- [x] chronologie gardée honnête
- [x] aucun scope creep G/H ouvert
- [x] runtime de prod non modifié
- [x] smoke Phase A vert
- [x] sub-agents utilisés
- [x] reviewer séparé utilisé
- [x] remarques valides du reviewer intégrées
- [x] autocritique finale incluse
- [x] contenu complet des fichiers touchés inclus ci-dessous, hors le report lui-même pour éviter une récursion absurde

## 22. Contenu complet de tous les fichiers touchés

### Note sur la récursion
Le contenu complet du report lui-même n'est pas recopié ici pour éviter une récursion infinie. Tous les autres fichiers modifiés/créés du lot sont recopiés intégralement.

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`
```dart
import 'dart:collection';

import 'battle_action.dart';
import 'battle_topology.dart';

/// Queue locale des étapes d'un tour singles.
///
/// Frontière Phase F volontairement stricte :
/// - cette queue ne devient pas un contrat public du runtime ;
/// - elle ne remplace ni `BattleTurnResult.timeline`, ni `BattleDecisionRequest` ;
/// - elle ne sait gérer que les grandes étapes réellement supportées aujourd'hui ;
/// - elle n'ouvre ni targeting riche, ni callbacks génériques, ni hooks.
///
/// Son rôle est uniquement de devenir la vraie source de vérité du scheduling
/// interne du tour :
/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`) ;
/// - de la fin de tour ;
/// - des checks post-résolution ;
/// - des remplacements déjà honnêtement supportés.
final class BattleTurnQueue {
  BattleTurnQueue(Iterable<BattleQueueStep> initialSteps)
      : _steps = ListQueue<BattleQueueStep>.of(initialSteps);

  final ListQueue<BattleQueueStep> _steps;

  bool get isEmpty => _steps.isEmpty;

  int get length => _steps.length;

  BattleQueueStep takeNext() {
    if (_steps.isEmpty) {
      throw StateError('BattleTurnQueue est vide.');
    }
    return _steps.removeFirst();
  }

  void pushBack(BattleQueueStep step) {
    _steps.addLast(step);
  }

  void pushBackAll(Iterable<BattleQueueStep> steps) {
    _steps.addAll(steps);
  }
}

/// Taxonomie volontairement petite des étapes que la queue peut transporter.
///
/// On choisit ici les vraies familles utiles au scheduling actuel, rien de plus.
enum BattleQueueStepKind {
  action,
  endOfTurn,
  postTurnChecks,
  autoSwitch,
  replacementRequired,
}

sealed class BattleQueueStep {
  const BattleQueueStep();

  BattleQueueStepKind get kind;
}

/// Retourne `true` seulement pour les actions réellement gérées par la queue.
///
/// Important :
/// - `Run` / `Capture` vivent encore hors queue car ils terminent
///   immédiatement le combat hors résolution normale ;
/// - `BattleActionNone` reste un marqueur d'étape inter-tour locale et ne doit
///   pas être déguisé en action de queue ;
/// - Phase F refuse donc de transformer toute `BattleAction` existante en
///   pseudo commande universelle.
bool isBattleQueueManagedAction(BattleAction action) {
  return action is BattleActionFight ||
      action is BattleActionRecharge ||
      action is BattleActionSwitch;
}

/// Étape de queue qui résout une action réellement jouée pendant le tour.
final class BattleQueueActionStep extends BattleQueueStep {
  factory BattleQueueActionStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required BattleAction action,
    bool wasForced = false,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueActionStep',
    );
    if (!isBattleQueueManagedAction(action)) {
      throw ArgumentError.value(
        action,
        'action',
        'BattleQueueActionStep n’accepte que Fight/Switch/Recharge.',
      );
    }
    return BattleQueueActionStep._(
      side: side,
      slot: slot,
      action: action,
      wasForced: wasForced,
    );
  }

  const BattleQueueActionStep._({
    required this.side,
    required this.slot,
    required this.action,
    required this.wasForced,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final BattleAction action;

  /// Distingue le switch volontaire de l'étape de remplacement forcé joueur.
  ///
  /// Phase F garde ce flag localement borné :
  /// - il ne s'applique utilement qu'aux `BattleActionSwitch` ;
  /// - il évite de recréer une seconde taxonomie de step juste pour préserver
  ///   la vérité d'un flow déjà supporté ;
  /// - il n'ouvre aucun targeting ni scheduler plus riche.
  final bool wasForced;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.action;
}

/// Étape explicite de fin de tour.
///
/// On la garde sans payload :
/// - la fin de tour actuelle s'applique encore au combat entier ;
/// - la vraie causalité vit dans l'engine de conditions et dans l'état courant ;
/// - ajouter ici des champs décoratifs ne ferait que gonfler l'API.
final class BattleQueueEndOfTurnStep extends BattleQueueStep {
  const BattleQueueEndOfTurnStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.endOfTurn;
}

/// Étape qui inspecte l'état après la fin de tour et insère les suites utiles.
///
/// Elle existe pour rendre explicite le moment où le moteur décide :
/// - un auto-remplacement ennemi ;
/// - un remplacement requis côté joueur ;
/// - ou rien.
final class BattleQueuePostTurnChecksStep extends BattleQueueStep {
  const BattleQueuePostTurnChecksStep();

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.postTurnChecks;
}

/// Étape de switch automatique déjà réellement supportée.
final class BattleQueueAutoSwitchStep extends BattleQueueStep {
  factory BattleQueueAutoSwitchStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required int reserveIndex,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueAutoSwitchStep',
    );
    return BattleQueueAutoSwitchStep._(
      side: side,
      slot: slot,
      reserveIndex: reserveIndex,
    );
  }

  const BattleQueueAutoSwitchStep._({
    required this.side,
    required this.slot,
    required this.reserveIndex,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final int reserveIndex;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.autoSwitch;
}

/// Étape explicite disant qu'un remplacement joueur est requis avant le tour
/// suivant.
///
/// Cette étape n'effectue pas le switch elle-même :
/// - le moteur singles actuel laisse encore ce remplacement au prochain
///   `decisionRequest` joueur ;
/// - Phase F rend simplement ce moment explicite dans le scheduling.
final class BattleQueueReplacementRequiredStep extends BattleQueueStep {
  factory BattleQueueReplacementRequiredStep({
    required BattleSideId side,
    required BattleSlotRef slot,
    required String faintedSpeciesId,
  }) {
    _validateSlotAttachment(
      expectedSide: side,
      slot: slot,
      stepLabel: 'BattleQueueReplacementRequiredStep',
    );
    return BattleQueueReplacementRequiredStep._(
      side: side,
      slot: slot,
      faintedSpeciesId: faintedSpeciesId,
    );
  }

  const BattleQueueReplacementRequiredStep._({
    required this.side,
    required this.slot,
    required this.faintedSpeciesId,
  });

  final BattleSideId side;
  final BattleSlotRef slot;
  final String faintedSpeciesId;

  @override
  BattleQueueStepKind get kind => BattleQueueStepKind.replacementRequired;
}

void _validateSlotAttachment({
  required BattleSideId expectedSide,
  required BattleSlotRef slot,
  required String stepLabel,
}) {
  if (slot.side != expectedSide) {
    throw ArgumentError(
      '$stepLabel attend un slot rattaché au side ${expectedSide.name}, '
      'mais a reçu ${slot.side.name}.',
    );
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
```dart
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
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

    // Phase F déplace ici la source de vérité du séquencement :
    // - `_resolveTurn` ne renvoie plus seulement "les deux actions puis un
    //   append post-traité" ;
    // - il consomme désormais une vraie queue locale incluant fin de tour et
    //   checks post-résolution ;
    // - le résultat qu'il renvoie est donc déjà le tour complet canonique.
    final turnResult = resolvedTurn.turnResult;

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      resolvedTurn.playerSide,
      resolvedTurn.enemySide,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: resolvedTurn.playerSide,
      enemySide: resolvedTurn.enemySide,
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
    // Review Phase F:
    // - le remplacement joueur inter-tour était encore sur un chemin manuel ;
    // - cela laissait une portion déjà supportée du flow hors scheduler
    //   canonique ;
    // - on le fait donc aussi passer par la queue, mais sans lui inventer
    //   une fausse fin de tour ni des checks post-résolution.
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
    );
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
    }

    return BattleSession._(
      state: BattleState(
        phase: BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
          timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
        ),
        outcome: null,
      ),
      setup: setup,
      rng: turn.rng,
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
  /// Phase F remplace ici l'ancien pipeline figé par une vraie queue locale :
  /// - l'ordre initial reste calculé honnêtement une seule fois au début ;
  /// - mais les étapes du tour passent ensuite par une file consommée ;
  /// - la fin de tour et les checks post-résolution sont insérés explicitement ;
  /// - les remplacements déjà supportés ne sont plus appendés "à côté" du tour.
  _ResolvedBattleTurn _resolveTurn(
    BattleAction playerAction,
    BattleAction enemyAction,
  ) {
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
    );
    final queue = BattleTurnQueue(
      _buildInitialTurnQueue(
        playerAction: playerAction,
        enemyAction: enemyAction,
        player: turn.playerSide.active,
        enemy: turn.enemySide.active,
        field: turn.field,
      ),
    );

    while (!queue.isEmpty) {
      final step = queue.takeNext();
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: step,
      );
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    return _ResolvedBattleTurn(
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      rng: turn.rng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: List<BattleMoveExecution>.unmodifiable(turn.executions),
        statusEvents: List<BattleStatusEvent>.unmodifiable(turn.statusEvents),
        volatileEvents:
            List<BattleVolatileEvent>.unmodifiable(turn.volatileEvents),
        fieldEvents: List<BattleFieldEvent>.unmodifiable(turn.fieldEvents),
        switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
        timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
      ),
    );
  }

  Iterable<BattleQueueStep> _buildInitialTurnQueue({
    required BattleAction playerAction,
    required BattleAction enemyAction,
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) sync* {
    final orderedActions = _resolveTurnOrder(
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: player,
      enemy: enemy,
      field: field,
    );

    for (final orderedAction in orderedActions) {
      if (!isBattleQueueManagedAction(orderedAction.action)) {
        continue;
      }

      yield BattleQueueActionStep(
        side: orderedAction.side,
        slot: BattleSlotRef.active(orderedAction.side),
        action: orderedAction.action,
        wasForced: false,
      );
    }
  }

  void _appendTurnTailWhenActionPhaseDrains({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    if (turn.turnTailScheduled || !queue.isEmpty) {
      return;
    }

    // La queue n'insère la fin de tour qu'une seule fois, exactement quand les
    // actions ordonnées du tour ont été consommées. C'est ce point d'insertion
    // explicite qui remplace l'ancien "et maintenant on fait la fin de tour"
    // codé en dur en bas de `_resolveTurn`.
    queue.pushBack(const BattleQueueEndOfTurnStep());
    queue.pushBack(const BattleQueuePostTurnChecksStep());
    turn.turnTailScheduled = true;
  }

  void _executeQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
    required BattleQueueStep step,
  }) {
    switch (step) {
      case BattleQueueActionStep():
        _executeActionQueueStep(turn: turn, step: step);
      case BattleQueueEndOfTurnStep():
        _executeEndOfTurnQueueStep(turn);
      case BattleQueuePostTurnChecksStep():
        _executePostTurnChecksQueueStep(
          queue: queue,
          turn: turn,
        );
      case BattleQueueAutoSwitchStep():
        _executeAutoSwitchQueueStep(turn: turn, step: step);
      case BattleQueueReplacementRequiredStep():
        _executeReplacementRequiredQueueStep(turn: turn, step: step);
    }
  }

  void _executeActionQueueStep({
    required _QueuedTurnContext turn,
    required BattleQueueActionStep step,
  }) {
    final actingSide = turn.side(step.side);
    final opposingSide = turn.side(_opposingSideId(step.side));

    if (step.action case BattleActionFight(:final move, :final moveIndex)) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _resolveMoveExecution(
        attackerLabel: step.side.actorId,
        move: move,
        moveIndex: moveIndex,
        attacker: actingSide.active,
        defender: opposingSide.active,
        field: turn.field,
        targetLabel: _opposingSideId(step.side).actorId,
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
      return;
    }

    if (step.action case BattleActionSwitch(:final reserveIndex)) {
      final resolution = _resolveSwitchAction(
        side: actingSide,
        reserveIndex: reserveIndex,
        wasForced: step.wasForced,
      );
      turn.updateSide(step.side, resolution.side);
      turn.switchEvents.add(resolution.event);
      turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
      return;
    }

    if (step.action is BattleActionRecharge) {
      if (actingSide.active.isFainted || opposingSide.active.isFainted) {
        return;
      }

      final resolution = _conditionEngine.runForcedContinueTurn(
        combatantLabel: step.side.actorId,
        combatant: actingSide.active,
      );
      turn.updateActive(step.side, resolution.combatant);
      turn.volatileEvents.addAll(resolution.volatileEvents);
      turn.timeline.addAll(_turnEventsFromVolatile(resolution.volatileEvents));
    }
  }

  void _executeEndOfTurnQueueStep(_QueuedTurnContext turn) {
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
        .addAll(_turnEventsFromStatus(residualResolution.statusEvents));
    turn.timeline.addAll(_turnEventsFromField(residualResolution.fieldEvents));
  }

  void _executePostTurnChecksQueueStep({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    final enemyReplacementIndex =
        _firstUsableReserveIndex(turn.enemySide.reserve);
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
        (!turn.enemySide.active.isFainted || enemyReplacementIndex != null) &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      // Le replacement joueur dépend ici du prochain état jouable du board,
      // pas seulement de l'état exact avant consommation du switch ennemi :
      // - en double K.O. avec réserve des deux côtés, l'ennemi auto-switchera ;
      // - le joueur doit donc bien recevoir une request de remplacement ;
      // - on l'insère après l'auto-switch ennemi pour conserver l'ordre
      //   historique déjà jugé honnête par les lots précédents.
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
    required _QueuedTurnContext turn,
    required BattleQueueAutoSwitchStep step,
  }) {
    final resolution = _resolveSwitchAction(
      side: turn.side(step.side),
      reserveIndex: step.reserveIndex,
      wasForced: true,
    );
    turn.updateSide(step.side, resolution.side);
    turn.switchEvents.add(resolution.event);
    turn.timeline.add(BattleTurnSwitchEvent(resolution.event));
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

    final playerSpeed = _resolveEffectiveSpeed(player);
    final enemySpeed = _resolveEffectiveSpeed(enemy);
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

class _OrderedBattleAction {
  const _OrderedBattleAction({
    required this.side,
    required this.action,
  });

  final BattleSideId side;
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

/// Contexte mutable strictement local à la consommation d'une queue de tour.
///
/// Phase F ne déplace pas la mutabilité vers `BattleState` :
/// - la session publique reste immutable ;
/// - ce contexte vit uniquement pendant `_resolveTurn` ;
/// - il sert à éviter de recopier manuellement le même faisceau de variables
///   `player/enemy/reserve/field/rng/events` dans chaque branche de queue.
final class _QueuedTurnContext {
  _QueuedTurnContext({
    required this.playerSide,
    required this.enemySide,
    required this.field,
    required this.rng,
  });

  BattleSideState playerSide;
  BattleSideState enemySide;
  BattleFieldState field;
  BattleRng rng;
  bool turnTailScheduled = false;

  final List<BattleMoveExecution> executions = <BattleMoveExecution>[];
  final List<BattleStatusEvent> statusEvents = <BattleStatusEvent>[];
  final List<BattleVolatileEvent> volatileEvents = <BattleVolatileEvent>[];
  final List<BattleFieldEvent> fieldEvents = <BattleFieldEvent>[];
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

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_queue_test.dart`
```dart
import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/battle_queue.dart';
import 'package:test/test.dart';

void main() {
  group('BattleTurnQueue Phase F', () {
    test(
        'preserves FIFO order while allowing explicit post-turn work to be appended dynamically',
        () {
      final queue = BattleTurnQueue(
        <BattleQueueStep>[
          BattleQueueActionStep(
            side: BattleSideId.player,
            slot: const BattleSlotRef.active(BattleSideId.player),
            action: const BattleActionSwitch(
              reserveIndex: 0,
            ),
          ),
          BattleQueueActionStep(
            side: BattleSideId.enemy,
            slot: const BattleSlotRef.active(BattleSideId.enemy),
            action: const BattleActionRecharge(),
          ),
        ],
      );

      expect(queue.isEmpty, isFalse);
      expect(queue.takeNext(), isA<BattleQueueActionStep>());

      queue.pushBack(const BattleQueueEndOfTurnStep());
      queue.pushBack(const BattleQueuePostTurnChecksStep());
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reserveIndex: 1,
        ),
      );
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: 'lead_player',
        ),
      );

      expect(queue.takeNext(), isA<BattleQueueActionStep>());
      expect(queue.takeNext(), isA<BattleQueueEndOfTurnStep>());
      expect(queue.takeNext(), isA<BattleQueuePostTurnChecksStep>());
      expect(queue.takeNext(), isA<BattleQueueAutoSwitchStep>());
      expect(queue.takeNext(), isA<BattleQueueReplacementRequiredStep>());
      expect(queue.isEmpty, isTrue);
    });

    test('queue steps reject mismatched side and slot attachments', () {
      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          action: const BattleActionRecharge(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.player),
          reserveIndex: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('queue-managed action steps reject out-of-turn actions', () {
      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: const BattleActionRun(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          action: const BattleActionNone(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_switch_test.dart`
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
```

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_field_test.dart`
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
  required List<BattleMoveData> playerMoves,
  required List<BattleMoveData> enemyMoves,
  BattleFieldState fieldState = const BattleFieldState(),
  BattleTypingSnapshot? playerTyping,
  BattleTypingSnapshot? enemyTyping,
  BattleMajorStatusState? playerStatus,
  BattleMajorStatusState? enemyStatus,
  BattleRng rng = const BattleSeededRng(),
  int playerSpeed = 70,
  int enemySpeed = 40,
  int playerHp = 100,
  int enemyHp = 100,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: BattleCombatantData(
        speciesId: 'playermon',
        level: 40,
        maxHp: playerHp,
        stats: _stats(speed: playerSpeed),
        typing: playerTyping,
        majorStatus: playerStatus,
        moves: playerMoves,
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'enemymon',
        level: 40,
        maxHp: enemyHp,
        stats: _stats(speed: enemySpeed),
        typing: enemyTyping,
        majorStatus: enemyStatus,
        moves: enemyMoves,
      ),
      isTrainerBattle: false,
      trainerId: null,
      fieldState: fieldState,
    ),
    rng: rng,
  );
}

int _damageTaken(BattleSession session, String target) {
  final execution = session.state.currentTurn!.executions.firstWhere(
    (execution) => execution.target == target && execution.damage > 0,
  );
  return execution.damage;
}

void main() {
  group('BattleSession BE9 field state', () {
    test('a rain move activates a real weather state with a visible trace', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'rain_dance',
            name: 'Rain Dance',
            power: 0,
            type: 'water',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.rain,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(afterTurn.state.field.weather?.remainingTurns, equals(4));
      expect(
        afterTurn.state.currentTurn!.fieldEvents
            .map((event) => event.kind)
            .toList(growable: false),
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherSet,
        ]),
      );
    });

    test('rain really boosts water damage and reduces fire damage', () {
      final neutralWater = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'water_gun',
            name: 'Water Gun',
            power: 40,
            type: 'water',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final rainyWater = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'water_gun',
            name: 'Water Gun',
            power: 40,
            type: 'water',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
        ),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final neutralFire = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'ember',
            name: 'Ember',
            power: 40,
            type: 'fire',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final rainyFire = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'ember',
            name: 'Ember',
            power: 40,
            type: 'fire',
            category: BattleMoveCategory.special,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
        ),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(
        _damageTaken(rainyWater, 'enemy'),
        greaterThan(_damageTaken(neutralWater, 'enemy')),
      );
      expect(
        _damageTaken(rainyFire, 'enemy'),
        lessThan(_damageTaken(neutralFire, 'enemy')),
      );
    });

    test(
        'a sandstorm move activates a real weather state and deals residual only to non-immune typings',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'sandstorm',
            name: 'Sandstorm',
            power: 0,
            type: 'rock',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            weatherEffect: BattleWeatherId.sandstorm,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerTyping: const BattleTypingSnapshot(primaryType: 'rock'),
        enemyTyping: const BattleTypingSnapshot(primaryType: 'grass'),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final residualEvent = afterTurn.state.currentTurn!.fieldEvents
          .where(
            (event) => event.kind == BattleFieldEventKind.weatherResidualDamage,
          )
          .single;

      expect(
          afterTurn.state.field.weather?.id, equals(BattleWeatherId.sandstorm));
      expect(afterTurn.state.field.weather?.remainingTurns, equals(4));
      expect(afterTurn.state.player.currentHp, equals(100));
      expect(afterTurn.state.enemy.currentHp, equals(94));
      expect(residualEvent.target, equals('enemy'));
      expect(residualEvent.damage, equals(6));
      final timeline = afterTurn.state.currentTurn!.timeline;
      final enemyActionIndex = timeline.lastIndexWhere(
        (event) =>
            event is BattleTurnExecutionEvent &&
            event.execution.attacker == 'enemy',
      );
      final residualIndex = timeline.lastIndexWhere(
        (event) =>
            event is BattleTurnFieldEvent &&
            event.event.kind == BattleFieldEventKind.weatherResidualDamage,
      );
      expect(residualIndex, greaterThan(enemyActionIndex));
    });

    test('Trick Room inverts speed order at equal priority only', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
          ),
          BattleMoveData(
            id: 'quick_attack',
            name: 'Quick Attack',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
            priority: 1,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            type: 'normal',
            category: BattleMoveCategory.physical,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerSpeed: 30,
        enemySpeed: 80,
        fieldState: const BattleFieldState(
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
      );

      final invertedTurn =
          session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(
        invertedTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );

      final priorityTurn =
          session.applyChoice(const PlayerBattleChoiceFight(1));
      expect(
        priorityTurn.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });

    test('a trick room move activates a real pseudoWeather state', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'trick_room',
            name: 'Trick Room',
            power: 0,
            type: 'psychic',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            priority: -7,
            pseudoWeatherEffect: BattlePseudoWeatherId.trickRoom,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(
        afterTurn.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(afterTurn.state.field.pseudoWeather?.remainingTurns, equals(4));
      expect(
        afterTurn.state.currentTurn!.fieldEvents.single.kind,
        equals(BattleFieldEventKind.pseudoWeatherSet),
      );
    });

    test(
        'recasting Trick Room clears the active pseudoWeather instead of silently stacking it',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'trick_room',
            name: 'Trick Room',
            power: 0,
            type: 'psychic',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.field,
            accuracy: BattleMoveAccuracy.alwaysHits(),
            priority: -7,
            pseudoWeatherEffect: BattlePseudoWeatherId.trickRoom,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 3,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.field.pseudoWeather, isNull);
      expect(
        afterTurn.state.currentTurn!.fieldEvents.single.kind,
        equals(BattleFieldEventKind.pseudoWeatherCleared),
      );
    });

    test('weather and Trick Room expire honestly at end of turn', () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'tail_whip',
            name: 'Tail Whip',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 1,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 1,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final kinds = afterTurn.state.currentTurn!.fieldEvents
          .map((event) => event.kind)
          .toList(growable: false);

      expect(afterTurn.state.field.weather, isNull);
      expect(afterTurn.state.field.pseudoWeather, isNull);
      expect(
        kinds,
        equals(<BattleFieldEventKind>[
          BattleFieldEventKind.weatherExpired,
          BattleFieldEventKind.pseudoWeatherExpired,
        ]),
      );
    });

    test(
        'major-status residuals and sandstorm coexist in the structured end-of-turn phase',
        () {
      final session = _session(
        playerMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        enemyMoves: const <BattleMoveData>[
          BattleMoveData(
            id: 'growl',
            name: 'Growl',
            power: 0,
            type: 'normal',
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.opponent,
          ),
        ],
        playerStatus: const BattleMajorStatusState.psn(),
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.sandstorm,
            remainingTurns: 2,
          ),
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.player.currentHp, equals(82));
      expect(
        afterTurn.state.currentTurn!.statusEvents.where(
            (event) => event.kind == BattleStatusEventKind.residualDamage),
        isNotEmpty,
      );
      expect(
        afterTurn.state.currentTurn!.fieldEvents.where(
          (event) => event.kind == BattleFieldEventKind.weatherResidualDamage,
        ),
        isNotEmpty,
      );
    });
  });
}
```

### `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_volatiles_test.dart`
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
      final timeline = afterRecharge.state.currentTurn!.timeline;
      final rechargeIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnVolatileEvent &&
            event.event.kind == BattleVolatileEventKind.rechargeTurnSpent,
      );
      final enemyExecutionIndex = timeline.indexWhere(
        (event) =>
            event is BattleTurnExecutionEvent &&
            event.execution.attacker == 'enemy',
      );
      expect(rechargeIndex, isNonNegative);
      expect(enemyExecutionIndex, greaterThan(rechargeIndex));
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
