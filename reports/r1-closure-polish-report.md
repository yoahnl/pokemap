# R1 Closure Polish Report

## 1. Résumé exécutif honnête

Ce passage de fermeture n'est pas un rerun de `R1`.
C'est un mini passage de cohérence et de verrouillage, exécuté sur un worktree déjà dirty par le passage `R1` précédent, sans aucun reset.

Constat principal:

- une vraie incohérence canonique résiduelle existait dans `docs/combat/battle-canonical-state-v3.1.md` : le document se présentait bien comme le canon battle après `R1`, mais conservait plus bas une ancienne section historique `Décision officielle après R0` annonçant encore `R1` comme prochaine étape officielle ;
- `BattleWaitReason.noLegalChoice` était déjà honnête dans son comportement, mais pas encore cadré assez explicitement, noir sur blanc, comme **dead-end unsupported** et non comme flow gameplay acceptable.

Décision retenue:

- corriger maintenant l'incohérence canonique réelle dans `docs/combat/battle-canonical-state-v3.1.md` ;
- ne pas toucher `docs/combat/battle-roadmap-canonical-v3.1.md`, qui est cohérent sur les surfaces relues ;
- ne pas implémenter `Struggle` ;
- ne pas symétriser artificiellement joueur/ennemi ;
- clarifier localement le sens de `noLegalChoice` dans `packages/map_battle/lib/src/battle_session.dart` ;
- verrouiller ce sens par test dans `packages/map_battle/test/battle_decision_request_test.dart`.

Résultat net:

- la contradiction canonique après `R1` a été supprimée ;
- `BattleWaitReason.noLegalChoice` est maintenant explicitement cadré comme état unsupported/dead-end côté joueur ;
- l'asymétrie actuelle joueur `BattleWaitRequest(noLegalChoice)` / ennemi `StateError` est assumée explicitement comme borne de `R1`, sans faux support nouveau ;
- aucune dérive vers `R2`, `R3`, `R4`, `H3` ou `Struggle` n'a été introduite.

## 2. Pré-gates réellement exécutés + résultats

Commandes exécutées exactement au début:

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réellement observés:

### `git status --short --untracked-files=all`

```text
 M docs/combat/battle-canonical-state-v3.1.md
 M docs/combat/battle-roadmap-canonical-v3.1.md
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/test/battle_decision_request_test.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
 M packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? reports/r1-battleable-slice-hardening-report.md
```

### `git diff --stat`

```text
 docs/combat/battle-canonical-state-v3.1.md         |  22 +--
 docs/combat/battle-roadmap-canonical-v3.1.md       |  14 +-
 packages/map_battle/lib/src/battle_session.dart    |  42 +++---
 .../test/battle_decision_request_test.dart         |  38 +++++
 packages/map_battle/test/battle_session_test.dart  |  94 ++++++++++++
 .../seeds/pokemon_moves_bootstrap_seed.dart        | 167 ++++++++++-----------
 .../test/pokemon_moves_bootstrap_seed_test.dart    |   9 +-
 .../runtime_battle_combatant_seed_builder.dart     |  12 +-
 ...runtime_battle_combatant_seed_builder_test.dart |   6 +
 .../test/runtime_battle_setup_mapper_test.dart     |   6 +
 10 files changed, 287 insertions(+), 123 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/r1-battleable-slice-hardening-report.md
```

## 3. État git initial exact et interprétation

Le repo était déjà **dirty** au début de ce passage.

Ce bruit n'était pas un incident du présent travail.
C'était la baseline du passage `R1` précédent.

Interprétation retenue:

- aucun reset ne devait être tenté ;
- aucun discard ne devait être tenté ;
- le présent passage devait être jugé uniquement sur les retouches supplémentaires strictement nécessaires pour fermer proprement `R1` ;
- il fallait distinguer clairement :
  - l'état dirty hérité de `R1` ;
  - les trois fichiers réellement retouchés dans ce passage de fermeture.

## 4. Méthode réellement suivie

Séquence réelle:

1. exécution des pré-gates obligatoires ;
2. relecture ciblée des docs canoniques `R0/R1` et des surfaces battle liées à `noLegalChoice` ;
3. classification explicite des sujets avant patch ;
4. audit parallèle demandé au battle-core semantics et à la cohérence canonique documentaire ;
5. constat d'une vraie contradiction résiduelle dans `battle-canonical-state-v3.1.md` par lecture directe locale ;
6. patch minimal sur trois fichiers ;
7. `dart analyze` + `dart test` sur `packages/map_battle` ;
8. correction d'un matcher de test trop générique après premier échec ;
9. rerun complet `dart analyze` + `dart test` sur `packages/map_battle` ;
10. review séparée finale ciblée sur les dérives de périmètre et la sémantique `noLegalChoice`.

## 5. Périmètre inclus / exclu

### Inclus

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md` en lecture seulement
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_session_test.dart` en lecture seulement
- `reports/r1-battleable-slice-hardening-report.md` en lecture seulement
- `reports/r0-truth-alignment-report.md` en lecture seulement
- le présent report final

### Exclus volontairement

- tout `packages/map_runtime/**`
- tout `packages/map_editor/**`
- host files
- seed files
- toute doc historique hors canon direct
- tout refactor structurel type `R2`
- toute ouverture `Struggle`
- toute symétrisation artificielle du cas joueur/ennemi
- tout widening de request / targeting / queue

## 6. Classification initiale des sujets

| Sujet | Classification | Décision initiale |
|---|---|---|
| incohérence canonique éventuelle dans `battle-canonical-state-v3.1.md` | `fix_now_small` | vérifier si un reliquat “après R0 -> prochaine étape R1” survit réellement ; corriger seulement si vrai |
| éventuelle incohérence canonique dans `battle-roadmap-canonical-v3.1.md` | `already_ok_do_not_touch` | relire, mais ne toucher que s'il reste une vraie contradiction |
| clarification de `BattleWaitReason.noLegalChoice` | `fix_now_small` | rendre la sémantique explicitement dead-end / unsupported |
| asymétrie joueur/ennemi sur “no legal move” | `document_now_only` | assumer explicitement l'asymétrie en `R1`, sans la corriger structurellement |
| toute autre modif | `defer_not_this_pass` | hors périmètre |

## 7. Fichiers lus

Docs canoniques et reports:

- `docs/combat/battle-canonical-state-v3.1.md`
- `docs/combat/battle-roadmap-canonical-v3.1.md`
- `reports/r1-battleable-slice-hardening-report.md`
- `reports/r0-truth-alignment-report.md`

Battle code/tests:

- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_session_test.dart`

Référence Showdown locale: non relue en profondeur dans ce passage, parce que les deux sujets ciblés étaient déjà bornés par la vérité canonique et le comportement local existant. Ce resserrement est volontaire et conforme au périmètre demandé.

## 8. Constats réels

### 8.1. Incohérence canonique réelle dans `battle-canonical-state-v3.1.md`

Constat:

- le document s'ouvre correctement comme canon battle après `R1` ;
- il annonce correctement en tête que la prochaine vraie étape officielle est `R2` ;
- mais plus bas, une ancienne section historique `Décision officielle après R0` survivait encore et réannonçait `R1` comme prochaine vraie étape officielle.

Ce n'était pas un simple détail de style.
C'était une contradiction interne réelle dans une source censée être canonique après `R1`.

### 8.2. `battle-roadmap-canonical-v3.1.md` n'avait pas besoin d'être retouché

Constat:

- la roadmap se présente explicitement comme la roadmap canonique du dépôt après `R1` ;
- elle conserve une section `Statut officiel après R0`, mais sous forme de traçabilité de phase, pas comme statut final du document ;
- elle annonce bien `R2` comme prochaine étape officielle après `R1`.

Conclusion:

- pas de contradiction canonique suffisamment forte pour justifier un patch dans ce passage.

### 8.3. `noLegalChoice` était déjà honnête en comportement, mais pas encore assez explicite en cadrage

Constat côté code:

- le moteur renvoyait déjà `BattleWaitRequest(reason: BattleWaitReason.noLegalChoice)` quand le joueur n'avait ni move, ni switch, ni capture, ni fuite honnêtes ;
- `applyChoice()` rejetait déjà toute tentative de forcer un input dans un `BattleWaitRequest` avec un message dédié mentionnant le reason ;
- l'ennemi sans move légal échouait déjà explicitement par `StateError`.

Constat côté vérité canonique:

- le document canonique mentionnait `Struggle` absent ;
- mais il ne disait pas encore assez explicitement que `BattleWaitReason.noLegalChoice` est un **dead-end unsupported** et non un flow acceptable.

### 8.4. L'asymétrie joueur/ennemi ne devait pas être “corrigée” ici

Constat:

- côté joueur, le moteur expose une surface publique `decisionRequest`, donc un `wait` explicite est la forme honnête la plus petite ;
- côté ennemi, le moteur n'expose pas de request publique et reste sur une garde interne `_chooseEnemyAction()` ;
- tenter de symétriser maintenant aurait demandé soit une nouvelle sémantique de forced action, soit un widening contractuel, soit un changement plus structurel.

Conclusion:

- cette asymétrie appartient encore à `R1` comme garde-fou de vérité, pas à un mini-fix structurel.

## 9. Décisions retenues / rejetées sujet par sujet

### 9.1. Incohérence canonique dans `battle-canonical-state-v3.1.md`

Décision retenue:

- **corriger maintenant**

Pourquoi:

- contradiction réelle dans une source canonique ;
- correction petite ;
- correction purement documentaire ;
- aucun risque de dérive de phase.

Décision rejetée:

- conserver la section historique “par traçabilité” dans ce document précis.

Pourquoi rejetée:

- dans le document d'état canonique après `R1`, cette section historique n'était plus neutre ;
- elle contredisait explicitement la temporalité affichée plus haut.

### 9.2. Incohérence éventuelle dans `battle-roadmap-canonical-v3.1.md`

Décision retenue:

- **ne pas toucher**

Pourquoi:

- aucune contradiction canonique forte détectée ;
- la section `Statut officiel après R0` reste lisible comme traçabilité de phase, pas comme statut final concurrent.

Décision rejetée:

- réécriture cosmétique pour harmoniser avec le canon d'état.

Pourquoi rejetée:

- ce serait une dérive documentaire sans gain de vérité suffisant pour ce passage.

### 9.3. Clarification de `BattleWaitReason.noLegalChoice`

Décision retenue:

- **clarifier maintenant** par commentaire moteur + doc canonique + test explicite

Pourquoi:

- le comportement était déjà globalement honnête ;
- le manque portait surtout sur la netteté du cadrage ;
- c'était exactement le type de fermeture `R1` demandé.

Décision rejetée:

- implémenter `Struggle`
- inventer un fallback joueur
- inventer un fallback ennemi
- ouvrir une nouvelle forme de request

Pourquoi rejetée:

- hors périmètre ;
- dérive vers une autre phase ;
- risque de faux support.

### 9.4. Asymétrie joueur/ennemi sur “no legal move”

Décision retenue:

- **assumer explicitement l'asymétrie**

Pourquoi:

- l'asymétrie reflète les seams réels du repo aujourd'hui ;
- la rendre visible est encore un travail `R1` ;
- la supprimer honnêtement demanderait plus qu'un mini passage de fermeture.

Décision rejetée:

- symétriser immédiatement les deux branches.

Pourquoi rejetée:

- ce serait un faux petit fix ;
- en pratique, cela déborderait vers du contrat ou du scheduling.

## 10. Justification précise des fichiers modifiés

### `docs/combat/battle-canonical-state-v3.1.md`

Touché pour deux raisons strictes:

1. supprimer la contradiction temporelle résiduelle `après R0 -> prochaine étape R1` dans un document qui se présente comme canon après `R1` ;
2. expliciter que `BattleWaitReason.noLegalChoice` côté joueur est un dead-end unsupported, pas un flow acceptable.

### `packages/map_battle/lib/src/battle_session.dart`

Touché uniquement pour ajouter un commentaire local utile sur la branche existante `noLegalChoice`.

Pourquoi ce commentaire appartenait encore à `R1`:

- il n'ouvre aucune mécanique ;
- il n'ouvre aucun seam nouveau ;
- il verrouille la vérité de périmètre ;
- il explique pourquoi l'asymétrie actuelle n'est pas un oubli silencieux mais une borne assumée de `R1`.

### `packages/map_battle/test/battle_decision_request_test.dart`

Touché pour verrouiller deux choses:

1. `noLegalChoice` n'attend aucun input ;
2. un input arbitraire reste rejeté explicitement dans cet état.

C'est un vrai verrou de sémantique, pas un test décoratif.

## 11. Justification des fichiers volontairement non touchés

### `docs/combat/battle-roadmap-canonical-v3.1.md`

Volontairement non touché.

Raison:

- relu ;
- aucune contradiction canonique suffisante ;
- pas de patch imaginaire.

### `packages/map_battle/test/battle_session_test.dart`

Volontairement non touché.

Raison:

- les tests de sémantique `noLegalChoice` étaient plus naturellement localisés dans `battle_decision_request_test.dart` ;
- dupliquer le verrou ailleurs n'apportait pas de vérité supplémentaire.

### `packages/map_runtime/**`, `packages/map_editor/**`, host files

Volontairement non touchés.

Raison:

- aucun des deux sujets ciblés ne l'exigeait ;
- toucher ces surfaces aurait été une dérive de périmètre.

## 12. Validations réellement relancées

Comme des fichiers `packages/map_battle/**` ont été touchés, les validations proportionnées demandées ont été relancées.

Commandes exécutées:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
```

Pourquoi deux passages:

- premier passage après le patch initial ;
- `dart test` a échoué une fois sur un matcher de test trop générique ;
- le test a été resserré sur le message réel du moteur ;
- second passage complet pour reverdir proprement.

Validations volontairement non lancées:

- `packages/map_runtime/**`
- `packages/map_editor/**`
- host tests

Raison:

- aucun fichier de ces zones n'a été modifié dans ce passage ;
- les relancer ici aurait été du bruit, pas une vraie vérification proportionnée.

## 13. Résultats réellement obtenus

### Premier passage

#### `dart analyze`

```text
Analyzing map_battle...
No issues found!
```

#### `dart test`

Résultat:

- échec unique sur le nouveau test `a noLegalChoice wait request rejects arbitrary player input`

Cause réelle:

- le moteur renvoyait déjà un message plus précis que le matcher écrit ;
- le test attendait un message contenant `illégal` et `wait` ;
- le moteur renvoyait en réalité : `Aucune décision joueur n’est attendue actuellement (noLegalChoice).`

Interprétation:

- ce n'était pas un bug moteur ;
- c'était un test mal cadré sur le vrai signal existant.

### Second passage

#### `dart analyze`

```text
Analyzing map_battle...
No issues found!
```

#### `dart test`

```text
00:00 +164: All tests passed!
```

## 14. Incidents rencontrés

### Incident 1 — faux négatif du sub-agent documentation

Le sub-agent documentation a conclu trop vite qu'aucune incohérence canonique ne subsistait.

Constat du rollout principal:

- c'était faux ;
- une vraie section contradictoire `après R0 -> prochaine étape R1` survivait plus bas dans `battle-canonical-state-v3.1.md`.

Décision:

- conserver la lecture directe locale comme source de vérité ;
- signaler dans ce report que le sub-agent a raté ce point.

### Incident 2 — premier matcher de test trop générique

Le premier matcher de test cherchait un message “choix illégal / wait”.
Le moteur exposait déjà un message plus spécifique, meilleur, mentionnant directement `noLegalChoice`.

Décision:

- ne pas dégrader le moteur pour coller au test ;
- resserrer le test sur le message réel.

## 15. Retour des sub-agents

### Sub-agent battle-core / semantics

Apport:

- a confirmé que le comportement de base autour de `noLegalChoice` était déjà honnête ;
- a jugé acceptable l'asymétrie joueur `wait` / ennemi `StateError` en fermeture `R1`.

Ce que je retiens:

- pas de correction comportementale lourde nécessaire ;
- pas de symétrisation artificielle.

Ce que je ne retiens pas tel quel:

- sa conclusion “ne rien toucher” était trop stricte pour la fermeture demandée ;
- le cadrage explicite restait malgré tout insuffisant dans le code et le canon battle.

### Sub-agent documentation / canon consistency

Apport:

- a relu les docs canoniques ciblées ;
- a confirmé que la roadmap canonique était cohérente sur son axe principal.

Ce que je retiens:

- `docs/combat/battle-roadmap-canonical-v3.1.md` n'avait pas besoin d'être touché.

Ce que je rejette:

- sa conclusion “aucune incohérence canonique résiduelle” sur `battle-canonical-state-v3.1.md`.

Pourquoi rejeté:

- la lecture directe du fichier a montré l'ancienne section `Décision officielle après R0` encore présente plus bas, avec `R1` comme prochaine étape officielle.

## 16. Retour du reviewer séparé

Reviewer utilisé:

- `Huygens`

Conclusion du reviewer:

- aucun finding bloquant

Points challengés par le reviewer:

- dérive hors périmètre ;
- contradiction canonique restante ;
- risque de sur-vendre `noLegalChoice` comme flow acceptable ;
- risque de glisser vers `R2`.

Ce que le reviewer a confirmé:

- pas de dérive hors périmètre ;
- plus de contradiction canonique sur les surfaces relues après patch ;
- `noLegalChoice` n'est pas sur-vendu comme flow acceptable ;
- le commentaire ajouté reste un cadrage local `R1`, pas un redesign.

Doute résiduel du reviewer:

- un simple angle de lecture: le report `R1` existant reste plus affirmatif que le commentaire code sur `noLegalChoice`, mais pas au point de créer une contradiction factuelle bloquante.

## 17. Critique explicite du prompt lui-même

### Ce qui était utile

- exiger un passage ciblé et non un rerun complet de `R1` ;
- imposer la baseline dirty comme donnée de départ ;
- interdire explicitement `Struggle` et les faux supports ;
- demander une classification avant patch ;
- autoriser de ne pas toucher un document si l'incohérence n'existe pas réellement.

### Ce qui était discutable

- la suspicion initiale sur l'incohérence documentaire était formulée comme possibilité ; c'était bien, mais il restait indispensable de vérifier tout le document, pas seulement son haut ;
- l'idée que beaucoup de commentaires seraient forcément nécessaires sur tout code touché peut être excessive sur un mini passage ; ici elle reste acceptable parce que le commentaire ajouté porte une vraie frontière de périmètre.

### Ce qui était trop rigide

- exiger absolument des sub-agents sur un passage aussi petit n'est pas toujours le meilleur coût/bénéfice ;
- ce tour en donne une preuve concrète : le sub-agent documentation a raté l'incohérence réelle, donc la lecture directe locale restait décisive.

### Ce que j'ai volontairement resserré

- je n'ai pas relu Showdown en profondeur ; cela aurait été du bruit hors périmètre ;
- je n'ai pas touché `battle-roadmap-canonical-v3.1.md` malgré son inclusion possible, car aucun patch réel n'y était justifié ;
- je n'ai pas tenté de “corriger” l'asymétrie joueur/ennemi, parce que ce serait déjà une autre phase.

## 18. Autocritique finale

Ce qui reste potentiellement discutable dans mon propre jugement:

- on peut défendre une lecture encore plus minimaliste où seule la doc canonique aurait dû être touchée ;
- j'ai quand même choisi d'ajouter un commentaire code et un test, car l'utilisateur demandait une clarification explicite et visible dans le repo, pas seulement dans un report.

Ce que je n'ai pas fait:

- je n'ai pas comparé à nouveau Showdown sur ce passage ;
- je n'ai pas relancé runtime/editor/host, volontairement.

Pourquoi je considère ce resserrement correct:

- le problème n'était ni un écart mécanique Showdown, ni un bug runtime ;
- c'était une contradiction canonique locale et une ambiguïté de vérité sur un dead-end déjà existant.

## 19. État git final utile

Après ce passage de fermeture:

- le worktree reste dirty, comme au départ ;
- aucune écriture Git n'a été faite ;
- trois fichiers existants ont été retouchés dans ce passage :
  - `docs/combat/battle-canonical-state-v3.1.md`
  - `packages/map_battle/lib/src/battle_session.dart`
  - `packages/map_battle/test/battle_decision_request_test.dart`
- un nouveau report a été créé :
  - `reports/r1-closure-polish-report.md`

Diff stat spécifique à ce passage sur les trois fichiers retouchés:

```text
 docs/combat/battle-canonical-state-v3.1.md         | 48 ++++--------
 packages/map_battle/lib/src/battle_session.dart    | 51 +++++++-----
 .../test/battle_decision_request_test.dart         | 90 ++++++++++++++++++++++
 3 files changed, 136 insertions(+), 53 deletions(-)
```

## 20. Checklist finale

- ai-je évité de rerun R1 au lieu de faire un passage ciblé ? oui
- ai-je gardé le périmètre strictement en fermeture R1 ? oui
- ai-je évité toute dérive vers R2/R3/R4/H3 ? oui
- ai-je corrigé une vraie incohérence canonique si elle existait réellement ? oui
- ai-je évité de forcer un patch documentaire imaginaire ? oui
- ai-je clarifié honnêtement `BattleWaitReason.noLegalChoice` ? oui
- ai-je évité d’implémenter `Struggle` ? oui
- ai-je évité d’ouvrir un nouveau flow gameplay ? oui
- ai-je relancé seulement les validations utiles ? oui
- ai-je utilisé des sub-agents ? oui
- ai-je tenté une review séparée ? oui
- ai-je inclus le contenu complet de tous les fichiers touchés ? oui, sauf le report lui-même pour éviter une récursion absurde explicitement signalée
- ai-je évité toute écriture Git interdite ? oui

## 21. Décision finale nette

### Ce passage de fermeture est-il réussi ?

- oui

### R1 peut-il être considéré proprement clos après ce passage ?

- oui

Raison principale:

- la dernière contradiction canonique réelle sur le document d'état après `R1` a été supprimée ;
- `noLegalChoice` est désormais encadré explicitement comme dead-end unsupported et non comme flow acceptable ;
- aucun faux support nouveau n'a été introduit ;
- aucune dérive de phase n'a été ouverte.

## 22. Contenu complet de tous les fichiers touchés

Note importante:

- le présent report n'est pas recopié dans lui-même, pour éviter une récursion absurde ;
- tous les autres fichiers touchés dans ce passage sont reproduits intégralement ci-dessous.

### 22.1. `docs/combat/battle-canonical-state-v3.1.md`

````md
# Battle Canonical State v3.1

Statut: canon battle actuel du dépôt après `R1 — Battleable Slice Hardening`

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

- la centralisation dans `packages/map_battle/lib/src/battle_session.dart`
- l'étroitesse des contracts requests / targeting / replacement
- la petitesse du scheduler local existant
- l'asymétrie entre conditions moteur et side conditions/hazards

La vérité produit actuelle est la suivante:

- un **golden slice battleable versionné** existe réellement
- un **host lançable** existe réellement
- un **bootstrap projet frais générique** existe réellement, mais il n'est pas équivalent à un projet battle-ready générique

Décision canonique après R1:

- la prochaine vraie étape officielle est `R2 — Scheduler Consolidation`

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

Ce seam existe déjà. Il ne faut plus le raconter comme “à créer”.

Fichier pivot:

- `packages/map_battle/lib/src/battle_queue.dart`

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
- scheduler local réel mais borné
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
| queue / scheduling | réel mais petit | faible structurellement, honnête localement | ne pas le raconter comme absent |
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

1. `battle_session.dart` reste trop central
2. le scheduler local existe mais reste trop petit pour des flows plus riches
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

- centralisation excessive dans `battle_session.dart`

### Scheduling

- queue locale réelle mais pas encore assez expressive pour des flows plus riches

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
````

### 22.2. `packages/map_battle/lib/src/battle_session.dart`

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
          choice as PlayerBattleChoiceSwitch,
        );
      }
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
    final outcome = resolvedTurn.pendingTurn != null
        ? null
        : _determineOutcome(
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
      pendingTurn: resolvedTurn.pendingTurn,
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
      originalPlayerAction:
          BattleActionSwitch(reserveIndex: choice.reserveIndex),
      originalEnemyAction: const BattleActionNone(),
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

    final followUpReplacementIndex =
        _firstUsableReserveIndex(turn.playerSide.reserve);
    if (turn.playerSide.active.isFainted && followUpReplacementIndex != null) {
      final replacementRequiredEvent = BattleSwitchEvent.replacementRequired(
        side: BattleSideId.player,
        fromSpeciesId: turn.playerSide.active.speciesId,
      );
      turn.switchEvents.add(replacementRequiredEvent);
      turn.timeline.add(BattleTurnSwitchEvent(replacementRequiredEvent));
    }

    final outcome = _determineOutcome(
      turn.playerSide,
      turn.enemySide,
      turn.field,
    );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: BattleTurnResult(
          playerAction: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          enemyAction: const BattleActionNone(),
          executions: const <BattleMoveExecution>[],
          stealthRockEvents:
              List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
          spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
          switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
          timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
        ),
        outcome: outcome,
      ),
      setup: setup,
      rng: turn.rng,
      pendingTurn: null,
    );
  }

  BattleSession _resumePendingTurnWithReplacement(
      PlayerBattleChoiceSwitch choice) {
    final pending = pendingTurn;
    if (pending == null) {
      throw StateError(
        'Aucune continuation de tour n’est disponible pour reprendre un remplacement joueur.',
      );
    }

    final turn = _QueuedTurnContext.resume(pending);
    final queue = BattleTurnQueue(
      <BattleQueueStep>[
        BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: BattleActionSwitch(reserveIndex: choice.reserveIndex),
          wasForced: true,
        ),
        ...pending.remainingSteps,
      ],
    );

    while (!queue.isEmpty) {
      _executeQueueStep(
        queue: queue,
        turn: turn,
        step: queue.takeNext(),
      );
      if (turn.pendingTurn != null) {
        break;
      }
      _appendTurnTailWhenActionPhaseDrains(
        queue: queue,
        turn: turn,
      );
    }

    final outcome = turn.pendingTurn != null
        ? null
        : _determineOutcome(
            turn.playerSide,
            turn.enemySide,
            turn.field,
          );

    return BattleSession._(
      state: BattleState(
        phase:
            outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
        playerSide: turn.playerSide,
        enemySide: turn.enemySide,
        field: turn.field,
        currentTurn: _buildTurnResultFromContext(
          turn: turn,
          playerAction: pending.playerAction,
          enemyAction: pending.enemyAction,
        ),
        outcome: outcome,
      ),
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
      originalPlayerAction: playerAction,
      originalEnemyAction: enemyAction,
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
      if (turn.pendingTurn != null) {
        break;
      }
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
      turnResult: _buildTurnResultFromContext(
        turn: turn,
        playerAction: playerAction,
        enemyAction: enemyAction,
      ),
      pendingTurn: turn.pendingTurn,
    );
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
        _executeActionQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueEndOfTurnStep():
        _executeEndOfTurnQueueStep(turn);
      case BattleQueuePostTurnChecksStep():
        _executePostTurnChecksQueueStep(
          queue: queue,
          turn: turn,
        );
      case BattleQueueAutoSwitchStep():
        _executeAutoSwitchQueueStep(
          queue: queue,
          turn: turn,
          step: step,
        );
      case BattleQueueReplacementRequiredStep():
        _executeReplacementRequiredQueueStep(turn: turn, step: step);
    }
  }

  void _executeActionQueueStep({
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

      final resolution = _resolveMoveExecution(
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
      final stealthRockResolution = _resolveStealthRockMoveEffect(
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
        turn.timeline
            .addAll(_turnEventsFromStealthRock(stealthRockResolution.events));
      }
      final spikesResolution = _resolveSpikesMoveEffect(
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
        turn.timeline.addAll(_turnEventsFromSpikes(spikesResolution.events));
      }
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
      final entryHazards = _resolveEntryHazards(
        side: turn.side(step.side),
      );
      turn.updateSide(step.side, entryHazards.side);
      turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
      turn.timeline
          .addAll(_turnEventsFromStealthRock(entryHazards.stealthRockEvents));
      turn.spikesEvents.addAll(entryHazards.spikesEvents);
      turn.timeline.addAll(_turnEventsFromSpikes(entryHazards.spikesEvents));

      final sideAfterEntry = turn.side(step.side);
      if (sideAfterEntry.active.isFainted &&
          step.side == BattleSideId.player &&
          _firstUsableReserveIndex(sideAfterEntry.reserve) != null &&
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
        !turn.enemySide.active.isFainted &&
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
      // Tant qu'une chaîne d'auto-switch ennemi reste possible, on refuse
      // d'annoncer le remplacement joueur trop tôt :
      // - sinon la timeline raconterait "le joueur doit remplacer" avant que
      //   l'ennemi ait fini d'entrer réellement ;
      // - en H1 Stealth Rock, un premier remplaçant ennemi peut même mourir
      //   en entrant, ce qui doit rester visible avant la request joueur.
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
    required BattleTurnQueue queue,
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
    final entryHazards = _resolveEntryHazards(
      side: turn.side(step.side),
    );
    turn.updateSide(step.side, entryHazards.side);
    turn.stealthRockEvents.addAll(entryHazards.stealthRockEvents);
    turn.timeline
        .addAll(_turnEventsFromStealthRock(entryHazards.stealthRockEvents));
    turn.spikesEvents.addAll(entryHazards.spikesEvents);
    turn.timeline.addAll(_turnEventsFromSpikes(entryHazards.spikesEvents));

    if (turn.side(step.side).active.isFainted) {
      final nextReserveIndex =
          _firstUsableReserveIndex(turn.side(step.side).reserve);
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
        _firstUsableReserveIndex(turn.playerSide.reserve) != null) {
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

  void _suspendTurnForImmediatePlayerReplacement({
    required BattleTurnQueue queue,
    required _QueuedTurnContext turn,
  }) {
    // H1/H2 ouvrent ici le plus petit vrai seam d'interruption :
    // - uniquement pour un remplacement joueur devenu obligatoire en plein tour
    //   parce qu'un switch-in vient de mourir sur un hazard d'entrée déjà
    //   réellement supporté ;
    // - on ne transforme pas cela en scheduler général ni en bus d'interruption ;
    // - on capture juste assez d'état pour reprendre honnêtement les étapes déjà
    //   en file après le futur choix de remplacement.
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
    required this.pendingTurn,
  });

  final BattleSideState playerSide;
  final BattleSideState enemySide;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
  final _PendingTurnContinuation? pendingTurn;
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

### 22.3. `packages/map_battle/test/battle_decision_request_test.dart`

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

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
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
    ),
  );
}

void main() {
  group('BattleSession Phase C decision requests', () {
    test('a free turn exposes a turn choice request with moves and switches',
        () {
      final session = _session(
        allowCapture: true,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
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

      final request = session.decisionRequest;

      expect(request, isA<BattleTurnChoiceRequest>());
      final turnChoiceRequest = request as BattleTurnChoiceRequest;
      expect(turnChoiceRequest.actor, equals(BattleDecisionActor.player));
      expect(turnChoiceRequest.side, equals(BattleSideId.player));
      expect(
        turnChoiceRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(turnChoiceRequest.moveChoices, hasLength(1));
      expect(turnChoiceRequest.switchChoices, hasLength(1));
      expect(turnChoiceRequest.captureChoice, isA<PlayerBattleChoiceCapture>());
      expect(turnChoiceRequest.runChoice, isA<PlayerBattleChoiceRun>());
    });

    test('a fainted active with a reserve exposes a forced replacement request',
        () {
      final session = _session(
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

      final request = session.decisionRequest;

      expect(request, isA<BattleForcedReplacementRequest>());
      final forcedReplacementRequest =
          request as BattleForcedReplacementRequest;
      expect(forcedReplacementRequest.side, equals(BattleSideId.player));
      expect(
        forcedReplacementRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        forcedReplacementRequest.reason,
        equals(BattleForcedReplacementReason.activeFainted),
      );
      expect(forcedReplacementRequest.switchChoices, hasLength(1));
      expect(
        forcedReplacementRequest.allowedChoices.single,
        isA<PlayerBattleChoiceSwitch>(),
      );
    });

    test('a forced recharge exposes a continue request with an explicit reason',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleContinueRequest>());
      final continueRequest = request as BattleContinueRequest;
      expect(continueRequest.side, equals(BattleSideId.player));
      expect(
        continueRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        continueRequest.reason,
        equals(BattleContinueReason.mustRecharge),
      );
      expect(continueRequest.allowedChoices, hasLength(1));
      expect(continueRequest.allowedChoices.single,
          isA<PlayerBattleChoiceContinue>());
    });

    test(
        'a battler with no usable move and no other legal choice exposes an explicit dead-end wait request',
        () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final request = session.decisionRequest;

      expect(request, isA<BattleWaitRequest>());
      final waitRequest = request as BattleWaitRequest;
      expect(waitRequest.side, equals(BattleSideId.player));
      expect(
        waitRequest.slot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(waitRequest.reason, equals(BattleWaitReason.noLegalChoice));
      expect(waitRequest.expectsInput, isFalse);
      expect(waitRequest.allowedChoices, isEmpty);
    });

    test('a noLegalChoice wait request rejects arbitrary player input', () {
      final session = _session(
        isTrainerBattle: true,
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: const <BattleMoveData>[
            BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        session.decisionRequest,
        isA<BattleWaitRequest>().having(
          (request) => request.reason,
          'reason',
          BattleWaitReason.noLegalChoice,
        ),
      );

      // R1 ferme ce cas comme dead-end explicite :
      // - aucun input joueur n'est attendu ;
      // - on ne doit donc pas pouvoir "forcer" un move arbitraire pour sortir
      //   du wait tant que `Struggle` n'est pas réellement supporté.
      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Aucune décision joueur n’est attendue actuellement'),
              contains('noLegalChoice'),
            ),
          ),
        ),
      );
    });

    test('request constructors reject mismatched side and slot attachments',
        () {
      expect(
        () => BattleContinueRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reason: BattleContinueReason.mustRecharge,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleWaitRequest(
          actor: BattleDecisionActor.player,
          side: BattleSideId.player,
          slot: const BattleSlotRef(
            side: BattleSideId.player,
            slotIndex: 1,
          ),
          reason: BattleWaitReason.noLegalChoice,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('an illegal choice for the current request kind is rejected cleanly',
        () {
      final session = _session(
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

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('forcedReplacement'),
          ),
        ),
      );
    });

    test('request transitions remain coherent across a forced continue turn',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(session.decisionRequest, isA<BattleContinueRequest>());

      final afterContinue =
          session.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterContinue.decisionRequest, isA<BattleTurnChoiceRequest>());
    });

    test('a finished battle exposes an explicit wait request', () {
      final session = _session(
        player: _combatant(
          speciesId: 'player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'tackle',
              name: 'Tackle',
              power: 200,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          maxHp: 1,
          currentHp: 1,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      final finishedSession =
          session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(finishedSession.state.isFinished, isTrue);
      expect(finishedSession.decisionRequest, isA<BattleWaitRequest>());
      expect(
        (finishedSession.decisionRequest as BattleWaitRequest).reason,
        equals(BattleWaitReason.battleFinished),
      );
    });
  });
}
````
