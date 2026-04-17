# Phase G — Contract Expansion Report

## 1. Résumé exécutif honnête

Verdict global : **vraie Phase G réussie**.

Ce lot n’a pas élargi `BattleMove`, `BattleCombatant`, `BattleFieldState` ou `BattleVolatileState` “par principe”. L’audit post-F a montré que le vrai blocage contractuel immédiat n’était pas dans ces états internes, mais dans les **contrats observables de résolution** : le moteur avait déjà une topologie `side/slot` canonique pour les requests, les switches et la queue, mais il retombait encore sur des chaînes `"player" / "enemy" / "field"` dans `BattleMoveExecution`, `BattleStatusEvent`, `BattleVolatileEvent` et la partie ciblée de `BattleFieldEvent`.

Le lot implémenté élargit donc **uniquement** ces contrats observables et leur production réelle :
- `BattleMoveExecution` porte maintenant `attackerSlot`, `attackerSide`, `targetKind` et `targetSlot` ;
- `BattleStatusEvent` porte maintenant `targetSlot` ;
- `BattleVolatileEvent` porte maintenant `actorSlot` et `targetSlot` ;
- `BattleFieldEvent` porte maintenant `targetSlot` seulement pour le cas réellement ciblé (`weatherResidualDamage`) ;
- `BattleConditionEngine` et `BattleSession` produisent ces refs typées en prod ;
- l’overlay runtime consomme désormais ces refs typées au lieu de dépendre des chaînes dérivées.

Ce qui n’a volontairement pas changé :
- pas de nouvelle mécanique H ;
- pas de hazards ;
- pas de selfSwitch / forceSwitch ;
- pas de sideConditions/slotConditions actives ;
- pas d’abilities / items / doubles ;
- pas de nouvelle fondation Phase E/F déguisée ;
- pas d’élargissement cosmétique de `BattleFieldState` ou `BattleVolatileState`.

Pourquoi c’est bien Phase G et pas H :
- on n’a ouvert **aucun comportement gameplay nouveau** ;
- on a seulement rendu les **contrats** de sortie cohérents avec la topologie déjà canonique du moteur ;
- chaque champ ajouté a un vrai cycle de vie et une vraie consommation en prod.

## 2. Verdict global

- **Statut** : Phase G réussie.
- **Nature du lot** : fondation contractuelle réelle, pas cosmétique.
- **Décision sur la suite** : **Phase H logique maintenant**, à condition de choisir un premier lot H petit et cohérent.

## 3. Pré-gates exécutés + résultats

Pré-gates read-only exécutés au début de ce lot :

- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

Résultat initial constaté : worktree propre au démarrage du lot Phase G.

Interprétation honnête :
- le lot a commencé sur un état lisible et stable ;
- aucune dette locale non commitée n’a pollué l’audit initial ;
- cela a rendu possible un vrai diagnostic “post-F” au lieu d’un tri de bruit local.

## 4. Méthode réelle utilisée

Ordre réellement suivi :

1. audit du worktree et relecture des reports Phase A à F ;
2. audit ciblé des contrats battle/runtime post-F ;
3. challenge design via sub-agents ;
4. choix d’un lot G minimal et vivant ;
5. TDD ciblé sur les nouvelles refs topologiques observables ;
6. implémentation minimale ;
7. format/analyze/tests ;
8. reviewer séparé ;
9. rerun final ;
10. report ultra-complet.

Méthodes/skills réellement utilisées :
- `superpowers:using-superpowers`
- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:test-driven-development`
- `superpowers:requesting-code-review`
- `superpowers:verification-before-completion`

Pourquoi ces skills étaient utiles ici :
- ce lot avait un vrai risque de faux progrès contractuel ;
- il fallait distinguer une vraie expansion G d’un gonflement mort ;
- le TDD a servi à prouver la vivacité des nouveaux champs ;
- la review séparée a servi à challenger le risque “typed fields décoratifs”.

## 5. Audit réel avant code

### 5.1. Où vivait le vrai blocage post-F

Confirmé par lecture de code :
- Phase C/D/F avaient déjà topologisé le **control plane** :
  - `BattleDecisionRequest.side/slot` dans `packages/map_battle/lib/src/battle_decision.dart`
  - `BattleSwitchEvent.side/slot` dans `packages/map_battle/lib/src/battle_switch.dart`
  - `BattleTurnQueue` avec `side/slot` dans `packages/map_battle/lib/src/battle_queue.dart`
- mais le **resolution plane observable** restait encore stringly-typed :
  - `BattleMoveExecution.attacker/target` en `String`
  - `BattleStatusEvent.target` en `String`
  - `BattleVolatileEvent.actor/target` en `String`
  - `BattleFieldEvent.target` en `String?`

Conséquence réelle :
- le moteur produisait encore une perte de vérité topologique au moment même où il racontait ce qu’il venait de résoudre ;
- le runtime/overlay continuait donc à consommer des surfaces affaiblies, alors que le moteur avait déjà fait l’effort structurel C/D/F.

### 5.2. Où la vieille forme restait bloquante

Confirmé par lecture de code :
- `battle_session.dart` reconstruisait encore des labels `actorId` / `'field'` au moment de créer les événements de résolution ;
- `battle_condition_engine.dart` recevait encore des labels textuels pour émettre ses événements ;
- `battle_overlay_component.dart` affichait encore les événements en lisant `execution.attacker`, `event.target`, `event.actor`.

### 5.3. Faux positifs écartés

Écartés explicitement après audit :
- élargir `BattleFieldState` avec terrain / conditions génériques : **hors lot ou champ mort** ;
- élargir `BattleVolatileState` vers un conteneur générique de volatiles : **champ mort / dérive H** ;
- ajouter `sideConditions` / `slotConditions` actives maintenant : **champ mort sans consommation réelle** ;
- élargir `BattleMove` avec de nouveaux payloads de mécaniques H sans lot H choisi : **anticipation cosmétique**.

## 6. Design retenu

### 6.1. Principe de design

Le design retenu est :

- **topologiser les contrats observables de résolution** ;
- garder des getters stringly-typed bornés comme seams de compatibilité ;
- ne pas élargir les états internes tant qu’aucun nouveau champ vivant n’est nécessaire.

### 6.2. Extensions réellement introduites

#### `BattleMoveExecution`
Changements :
- `attackerSlot: BattleSlotRef`
- `attackerSide` dérivé
- `targetKind: BattleMoveExecutionTargetKind`
- `targetSlot: BattleSlotRef?`
- `targetSide` dérivé
- getters de compatibilité : `attacker`, `target`

Justification :
- l’exécution de move est l’un des contrats battle les plus centraux et les plus visibles ;
- elle devait cesser de retomber sur `"player" / "enemy" / "field"` alors que la topologie Phase D existait déjà.

#### `BattleStatusEvent`
Changements :
- `targetSlot: BattleSlotRef`
- `targetSide` dérivé
- getter de compatibilité `target`

Justification :
- les statuts majeurs déjà supportés visent toujours un combattant actif ;
- ils ont donc un vrai slot de vie honnête maintenant.

#### `BattleVolatileEvent`
Changements :
- `actorSlot: BattleSlotRef`
- `targetSlot: BattleSlotRef?`
- `actorSide` / `targetSide` dérivés
- getters de compatibilité `actor` / `target`

Justification :
- `protect`, `breakProtect`, `recharge`, `chargeThenStrike` étaient déjà vivants ;
- leurs événements avaient besoin d’une source et d’une cible topologiques honnêtes.

#### `BattleFieldEvent`
Changements :
- `targetSlot: BattleSlotRef?`
- `targetSide` dérivé
- getter de compatibilité `target`

Frontière volontaire :
- on n’a **pas** attaché artificiellement un slot à tous les événements de champ ;
- seul le cas réellement ciblé (`weatherResidualDamage`) a reçu un `targetSlot`.

### 6.3. Pourquoi ce design est meilleur que l’ancien

- il ferme la dernière grande fuite stringly-typed post-C/D/F sur les surfaces observables ;
- il reste petit ;
- il ne crée aucun conteneur mort ;
- il donne à H un sol contractuel plus honnête sans ouvrir H.

### 6.4. Ce qui a été refusé

Refus explicites :
- `sideConditions` / `slotConditions` actives dans l’état ;
- terrain dans `BattleFieldState` ;
- conteneur générique de conditions ;
- volatiles généralisés ;
- champs préparatoires sans consommation ;
- tout lot H déguisé.

## 7. Critique explicite du prompt

Ce que le prompt avait juste :
- exiger une Phase G réelle et non décorative ;
- interdire les champs morts ;
- interdire l’ouverture cachée de H ;
- forcer un audit avant code.

Ce qui était discutable :
- la zone de travail prioritaire insistait beaucoup sur `BattleMove`, `BattleState`, `BattleFieldState`, `BattleVolatileState`, ce qui pouvait pousser vers une mauvaise intuition : “G = grossir les gros modèles d’état”.

Recadrage retenu :
- l’audit réel a montré que le premier vrai trou G post-F était surtout dans `battle_resolution.dart` et les contrats d’événements observables, pas dans les grands conteneurs d’état.

Ce qui aurait été dangereux si suivi aveuglément :
- ajouter `sideConditions`, `slotConditions`, terrain ou des payloads de mécaniques H “pour préparer” ;
- cela aurait produit des champs morts et un faux progrès.

## 8. Périmètre inclus / exclu

### Inclus
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_condition_engine.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_condition_engine_test.dart`
- `packages/map_battle/test/battle_field_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `reports/phase-g-contract-expansion-report.md`

### Exclus volontairement
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_queue.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_runtime/lib/src/application/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `examples/**`

Justification :
- aucun de ces fichiers n’avait besoin d’un changement vivant pour ce lot précis.

## 9. Plan local retenu

1. auditer la cohérence post-F entre topologie et contrats observables ;
2. classifier les candidats ;
3. choisir un lot minimal centré sur les contrats de résolution/événements ;
4. écrire les tests de vivacité ;
5. migrer la prod ;
6. faire consommer les nouveaux champs par l’overlay ;
7. valider ;
8. reviewer ;
9. reporter.

## 10. Justification fichier par fichier

- `packages/map_battle/lib/src/battle_resolution.dart`
  - Contrat central des exécutions de moves élargi avec refs topologiques vivantes.
- `packages/map_battle/lib/src/battle_status.dart`
  - Les événements de statut ont maintenant un vrai slot cible.
- `packages/map_battle/lib/src/battle_volatile.dart`
  - Les événements volatiles ont maintenant une vraie source et une vraie cible topologiques.
- `packages/map_battle/lib/src/battle_field.dart`
  - Le résiduel météo ciblé cesse d’être stringly-typed ; les autres cas restent globaux.
- `packages/map_battle/lib/src/battle_condition_engine.dart`
  - L’engine produit réellement les nouvelles refs au lieu d’émettre encore des chaînes.
- `packages/map_battle/lib/src/battle_session.dart`
  - La session construit maintenant des exécutions topologiques et cesse d’aplatir la cible observable.
- `packages/map_battle/test/battle_condition_engine_test.dart`
  - Prouve que les nouveaux champs sont réellement produits par l’engine.
- `packages/map_battle/test/battle_field_test.dart`
  - Prouve que l’exécution move et le résiduel météo portent les bons refs topologiques.
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - Consomme les nouvelles refs typées en prod pour éviter des champs morts.
- `packages/map_runtime/test/battle_overlay_component_test.dart`
  - Adapte le seam de test au nouveau constructeur d’exécution.

## 11. Classification des blockers réellement adressés

### Blocker adressé

**required_now**
- contrats observables de résolution encore stringly-typed alors que control plane et queue sont déjà topologiques.

### Blockers explicitement non adressés

**not_required_yet**
- `BattleMove`
- `BattleCombatant`
- `BattleFieldState`
- `BattleVolatileState`
- `BattleSetup`
- `BattleDecisionRequest`
- `BattleTurnQueue`
- `BattleSwitchEvent`

**rejected_dead_field**
- sideConditions actives
- slotConditions actives
- terrain
- pseudo container générique de conditions
- volatiles génériques

**belongs_to_H_not_G**
- hazards
- selfSwitch / forceSwitch
- abilities / items
- terrains riches
- doubles
- phazing / targeting riche

## 12. Contrats changés / non changés et pourquoi

### `BattleMove`
- **Non changé**
- Pourquoi : aucun nouveau payload de move n’était requis pour ce lot ; l’audit ne justifiait pas d’ajouter des effets H morts.
- Lien avec G : audité, jugé suffisant pour maintenant.
- Lien avec H : certains futurs lots H pourront exiger de vrais nouveaux payloads, mais pas encore.

### `BattleState`
- **Non changé**
- Pourquoi : la topologie Phase D était déjà suffisante pour ce lot.
- Lien avec G : déjà canonique ; pas le bon endroit du trou contractuel.
- Lien avec H : pourra servir de support futur, mais sans ajout mort maintenant.

### `BattleFieldState`
- **Non changé**
- Pourquoi : le champ actuel porte honnêtement `weather` et `pseudoWeather` déjà supportés.
- Lien avec G : audité et explicitement laissé inchangé.
- Lien avec H : side/slot conditions, terrain riche, etc. relèvent de futurs lots H choisis.

### `BattleVolatileState`
- **Non changé**
- Pourquoi : assez petit mais encore honnête pour le sous-ensemble actuel.
- Lien avec G : aucun champ vivant nouveau n’était justifié.
- Lien avec H : de futurs volatiles plus riches pourront exiger un élargissement ciblé, pas une généralisation vide maintenant.

### `BattleSetup`
- **Non changé**
- Pourquoi : aucun besoin setup/session/outcome supplémentaire pour ce lot.

### `BattleResolution` (`BattleMoveExecution` surtout)
- **Changé**
- Pourquoi : vrai trou contractuel observable post-F.
- Lien avec G : contrat de sortie enrichi sans ouvrir de mécanique.
- Lien avec H : H pourra désormais s’appuyer sur des sorties topologiques cohérentes.

### `BattleStatusEvent`
- **Changé**
- Pourquoi : événements majeurs encore stringly-typed ; désormais rattachés à un vrai slot.

### `BattleVolatileEvent`
- **Changé**
- Pourquoi : source/cible volatiles topologiques nécessaires pour arrêter la perte de vérité.

### `BattleFieldEvent`
- **Changé partiellement**
- Pourquoi : seul le résiduel météo avait une vraie cible combattant à typer.
- Justification de non-ajout plus large : les autres événements de champ restent honnêtement globaux.

### `BattleConditionEngine`
- **Changé**
- Pourquoi : doit produire réellement les nouveaux champs, sinon ils seraient morts.

### `BattleSession`
- **Changé**
- Pourquoi : doit construire des exécutions et cibles observables typées.

### `BattleDecision`
- **Non changé**
- Pourquoi : déjà suffisamment topologique depuis Phase C/D.

### `BattleQueue`
- **Non changé**
- Pourquoi : déjà suffisamment explicite depuis Phase F ; aucune nouvelle taxonomie requise pour G.

### `BattleSwitch`
- **Non changé**
- Pourquoi : déjà topologique et honnête ; sert plutôt de référence au reste.

## 13. Commandes réellement exécutées

Pré-gates :
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git ls-files --others --exclude-standard`

Audit/lecture :
- lectures `sed -n` ciblées des reports Phase A à F
- lectures `sed -n` ciblées des fichiers battle/runtime concernés
- recherches `rg` ciblées sur les contrats, les timelines et les usages tests/runtime
- lecture des skills Superpowers utilisés pour ce lot

Validation intermédiaire :
- `dart analyze lib test` dans `packages/map_battle`
- `dart test test/battle_condition_engine_test.dart test/battle_field_test.dart` dans `packages/map_battle`
- `flutter test test/battle_overlay_component_test.dart` dans `packages/map_runtime`
- `flutter test test/runtime_battle_setup_mapper_test.dart` dans `packages/map_runtime`

Format :
- `dart format packages/map_battle/lib/src/battle_condition_engine.dart packages/map_battle/lib/src/battle_field.dart packages/map_battle/lib/src/battle_resolution.dart packages/map_battle/lib/src/battle_session.dart packages/map_battle/lib/src/battle_status.dart packages/map_battle/lib/src/battle_volatile.dart packages/map_battle/test/battle_condition_engine_test.dart packages/map_battle/test/battle_field_test.dart packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart packages/map_runtime/test/battle_overlay_component_test.dart`

Validation finale :
- `dart analyze lib test` dans `packages/map_battle`
- `dart test` dans `packages/map_battle`
- `flutter analyze --no-pub lib/src/presentation/flame/battle_overlay_component.dart test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart` dans `packages/map_runtime`
- `flutter test test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart` dans `packages/map_runtime`

Sub-agents / review :
- audit/design sub-agent
- scope-creep sub-agent
- reviewer séparé final

## 14. Résultats réels format / analyze / tests / smoke

### Format
- `dart format` : vert
- 10 fichiers formatés, 3 effectivement réécrits par le formateur

### Analyze battle
- `dart analyze lib test` : vert

### Tests battle
- `dart test` : vert

### Analyze runtime
- `flutter analyze --no-pub ...` ciblé : vert

### Tests runtime
- `flutter test test/battle_overlay_component_test.dart test/runtime_battle_setup_mapper_test.dart test/phase_a_golden_battle_slice_smoke_test.dart` : vert

### Smoke produit Phase A
- `phase_a_golden_battle_slice_smoke_test.dart` : vert

### Ce qui est confirmé par exécution
- les nouveaux champs compile-time survivent au formattage et à l’analyse ;
- ils sont réellement produits par le moteur ;
- l’overlay runtime reste vert ;
- le seam runtime setup battle reste vert ;
- le smoke golden slice Phase A ne régresse pas.

## 15. Incidents rencontrés

Incident principal :
- plusieurs tentatives initiales de reviewer séparé via agents préexistants ont timeout / stagné.

Résolution :
- fermeture des agents devenus inutiles ;
- spawn d’un reviewer étroitement cadré sur les fichiers touchés ;
- retour final exploitable obtenu.

Impact :
- aucun impact sur le code ;
- seulement un petit coût de méthode/documentation.

## 16. Décisions retenues / rejetées

### Retenues
- topologiser les contrats observables de résolution ;
- garder des getters stringly-typed de compatibilité dérivés ;
- migrer l’overlay runtime pour consommer les refs typées.

### Rejetées
- ajouter des conteneurs side/slot conditions dès maintenant ;
- élargir `BattleFieldState` avec terrain ;
- élargir `BattleVolatileState` en structure générique ;
- ajouter des payloads H sur `BattleMove` sans lot H choisi ;
- toucher `packages/map_runtime/lib/src/application/**` ;
- toucher `examples/**`, `map_editor/**`, `map_core/**`.

## 17. Retour des sub-agents

### Sub-agent audit/design
Conclusion retenue :
- la vraie incohérence post-F était bien dans les **contrats observables de résolution** ;
- le lot proposé est une vraie Phase G, pas cosmétique ;
- la bonne frontière n’était pas de “mettre `BattleSideId` partout”, mais de rendre la sortie moteur topologique avec un modèle minimal de cible combattant vs field.

Ce que j’ai retenu :
- recentrer G sur `BattleMoveExecution` / `BattleStatusEvent` / `BattleVolatileEvent` / `BattleFieldEvent` ;
- garder les événements purement field-level honnêtement globaux.

Ce que j’ai rejeté :
- l’idée d’aller jusqu’à un nouveau type cible plus ambitieux ou un mini framework de participants. L’enum + `targetSlot?` était suffisant ici.

### Sub-agent scope-creep
Conclusion retenue :
- les conteneurs `sideConditions` / `slotConditions` / terrain / conditions génériques seraient morts aujourd’hui.

Ce que j’ai retenu :
- ne pas toucher `BattleMove`, `BattleFieldState`, `BattleVolatileState`, `BattleState` sans besoin vivant ;
- classifier explicitement ces directions comme `not_required_yet`, `rejected_dead_field` ou `belongs_to_H_not_G`.

Ce que j’ai rejeté :
- l’idée que le seul G possible serait un nouveau payload `BattleMove` pour un futur lot H choisi. C’est un bon signal de prudence, mais l’audit local montrait déjà un trou G autonome et plus urgent dans les contrats observables.

## 18. Retour du reviewer séparé

Reviewer séparé final : **Locke**.

Retour reçu :
- **No concrete findings.**

Interprétation honnête :
- le reviewer n’a trouvé ni champ mort évident, ni scope creep H, ni incohérence manifeste entre refs typées et getters de compatibilité.

## 19. Corrections appliquées après review

- aucune correction code supplémentaire n’a été requise après le reviewer final ;
- le reviewer n’a pas remonté de finding concret à corriger.

## 20. Autocritique finale

Ce que le lot améliore réellement :
- la cohérence topologique du moteur observable ;
- la vérité contractuelle de la timeline et des événements ;
- la base de lecture/consommation pour de futurs lots H.

Limites assumées :
- ce lot ne débloque **aucune mécanique H à lui seul** ;
- il ne fournit pas encore de conteneur side/slot conditions actives ;
- il ne résout pas la question du prochain **choix stratégique de H**.

Point de vigilance restant :
- certaines signatures internes du condition engine manipulent encore des refs de “défenseur/opposant” là où, conceptuellement, un futur H plus riche distinguera mieux la cible réelle. Pour le sous-ensemble actuel, c’est honnête et suffisant ; pour H riche, cela devra être réévalué lot par lot, pas anticipé maintenant.

## 21. État git final utile

Cette section a été mise à jour après création du report. Voir plus bas l’état Git final exact.

## 22. Checklist finale

- [x] audit réel avant code
- [x] critique explicite du prompt
- [x] classification explicite des candidats
- [x] lot minimal et borné
- [x] pas de mécanique H ouverte
- [x] pas de champ mort volontaire
- [x] vrais nouveaux champs produits en prod
- [x] vraie consommation runtime minimale
- [x] tests utiles ajoutés/durcis
- [x] format relancé
- [x] analyze relancé
- [x] tests relancés
- [x] smoke Phase A relancé
- [x] sub-agent audit/design utilisé
- [x] sub-agent scope creep utilisé
- [x] reviewer séparé utilisé
- [x] autocritique finale
- [x] annexe avec contenu complet des fichiers touchés (hors report lui-même)
- [x] aucune écriture Git interdite

## 23. Décision finale

- **Décision lot** : vraie Phase G réussie.
- **Suite nette** : **Phase H logique maintenant**.

Ce que G débloque réellement pour H :
- un moteur dont les sorties observables sont enfin cohérentes avec la topologie interne ;
- un meilleur support pour les futures mécaniques singles ciblées qui auront besoin de traces side/slot honnêtes ;
- moins de risque de réintroduire des strings plats là où le moteur a déjà investi dans `side/slot`.

Ce que G ne débloque toujours pas :
- hazards ;
- selfSwitch / forceSwitch ;
- side/slot conditions actives ;
- items / abilities ;
- targeting riche / doubles ;
- expansion large des modèles d’état.

## 24. Contenu complet de tous les fichiers touchés

Le report n’inclut pas son propre contenu complet pour éviter une récursion absurde. En revanche, tous les autres fichiers touchés sont inclus ci-dessous intégralement.

### `packages/map_battle/lib/src/battle_condition_engine.dart`

```dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
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
  ///
  /// Phase G ajoute ici un point de vérité topologique utile :
  /// - l'engine ne reçoit plus seulement `"player"` / `"enemy"` ;
  /// - il reçoit le slot réellement concerné ;
  /// - les événements observables émis par l'engine cessent donc d'aplatir la
  ///   topologie déjà introduite par les lots C/D/F.
  BattleActionAttemptResult runActionAttempt({
    required BattleSlotRef attackerSlot,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleRng rng,
  }) {
    final preparation = _volatileRules.prepareActionAttempt(
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
    );
    final actionGate = _statusRules.runActionAttemptGate(
      combatantSlot: attackerSlot,
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
      attackerSlot: attackerSlot,
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
    required BattleSlotRef attackerSlot,
    required BattleSlotRef targetSlot,
    required BattleCombatant attacker,
    required BattleCombatant defender,
  }) {
    return _volatileRules.runHitInterception(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
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
  ///
  /// Frontière volontaire Phase G :
  /// - on enrichit seulement les références topologiques de sortie ;
  /// - on n'ouvre aucune nouvelle famille d'effet de move ici.
  BattleMoveResolvedConditionResult runMoveResolved({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef targetSlot,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required bool wasImmune,
    required BattleRng rng,
  }) {
    final statusApplication = _statusRules.runMoveResolved(
      move: move,
      targetSlot: targetSlot,
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
      attackerSlot: attackerSlot,
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
  ///
  /// Phase G garde ce seam minuscule :
  /// - un slot explicite pour rattacher honnêtement l'événement produit ;
  /// - aucun système plus riche de verrous ou de commandes forcées.
  BattleForcedContinueTurnResult runForcedContinueTurn({
    required BattleSlotRef combatantSlot,
    required BattleCombatant combatant,
  }) {
    return _volatileRules.runForcedContinueTurn(
      combatantSlot: combatantSlot,
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
    required BattleSlotRef combatantSlot,
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
          targetSlot: combatantSlot,
          status: BattleMajorStatusId.par,
        ),
      ],
    );
  }

  _StatusMoveResolvedResult runMoveResolved({
    required BattleMove move,
    required BattleSlotRef targetSlot,
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
            targetSlot: targetSlot,
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
            targetSlot: targetSlot,
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
          targetSlot: targetSlot,
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
            combatantSlot: const BattleSlotRef.active(BattleSideId.player),
          )
        : _SingleStatusResidual(
            combatant: player,
            statusEvents: const <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyResidualForCombatant(
            combatant: enemy,
            combatantSlot: const BattleSlotRef.active(BattleSideId.enemy),
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
    required BattleSlotRef combatantSlot,
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
          targetSlot: combatantSlot,
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
    required BattleSlotRef attackerSlot,
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
            actorSlot: attackerSlot,
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
            actorSlot: attackerSlot,
            sourceMoveId: release.moveId,
            chargeStateId: release.chargeStateId,
          ),
      ],
    );
  }

  BattleHitInterceptionResult runHitInterception({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef targetSlot,
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
          actorSlot: attackerSlot,
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
          actorSlot: attackerSlot,
          targetSlot: targetSlot,
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
        actorSlot: attackerSlot,
        targetSlot: targetSlot,
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
    required BattleSlotRef attackerSlot,
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
          actorSlot: attackerSlot,
          sourceMoveId: move.id,
        ),
      ],
    );
  }

  BattleForcedContinueTurnResult runForcedContinueTurn({
    required BattleSlotRef combatantSlot,
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
          actorSlot: combatantSlot,
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
      combatantSlot: const BattleSlotRef.active(BattleSideId.player),
    );
    final enemyResidual = _applySandstormResidual(
      combatant: enemy,
      combatantSlot: const BattleSlotRef.active(BattleSideId.enemy),
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
    required BattleSlotRef combatantSlot,
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
          targetSlot: combatantSlot,
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

### `packages/map_battle/lib/src/battle_field.dart`

```dart
import 'battle_topology.dart';

/// Identifiant de météo réellement supporté par le moteur battle BE9.
///
/// Ce type reste volontairement étroit :
/// - `rain` pour la météo posée par l'équivalent de Rain Dance ;
/// - `sandstorm` pour le résiduel simple de tempête de sable ;
/// - aucun autre weather tant qu'il ne produit pas un vrai comportement
///   moteur local, testé et observable.
enum BattleWeatherId {
  rain,
  sandstorm,
}

/// Identifiant de pseudoWeather réellement supporté par le moteur battle BE9.
///
/// On n'ouvre pas ici une taxonomie générique de rooms / field effects :
/// - seul `trickRoom` est réellement consommé ;
/// - il agit uniquement sur l'ordre d'action à priorité égale ;
/// - aucun terrain, aucun side/slot state, aucun doubles.
enum BattlePseudoWeatherId {
  trickRoom,
}

/// État d'une météo active dans le combat.
///
/// Le contrat porte seulement :
/// - quel weather est actif ;
/// - combien de fins de tour il lui reste à survivre.
///
/// BE9 choisit une durée explicite plutôt qu'une magie implicite :
/// - le compteur est décrémenté à la fin de chaque tour ;
/// - une météo posée pendant un tour compte déjà ce tour dans sa durée ;
/// - cela garde une lecture locale simple et testable.
final class BattleWeatherState {
  const BattleWeatherState({
    required this.id,
    required this.remainingTurns,
  }) : assert(
          remainingTurns >= 1,
          'BattleWeatherState remainingTurns must be >= 1.',
        );

  final BattleWeatherId id;
  final int remainingTurns;

  BattleWeatherState decrement() {
    if (remainingTurns <= 1) {
      throw StateError(
        'BattleWeatherState cannot be decremented below 1 remaining turn.',
      );
    }
    return BattleWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// État d'un pseudoWeather actif dans le combat.
///
/// Même règle que pour la météo :
/// - un seul pseudoWeather BE9 est réellement porté ;
/// - il a une durée explicite ;
/// - aucune pile générique de conditions de champ n'est ouverte.
final class BattlePseudoWeatherState {
  const BattlePseudoWeatherState({
    required this.id,
    required this.remainingTurns,
  }) : assert(
          remainingTurns >= 1,
          'BattlePseudoWeatherState remainingTurns must be >= 1.',
        );

  final BattlePseudoWeatherId id;
  final int remainingTurns;

  BattlePseudoWeatherState decrement() {
    if (remainingTurns <= 1) {
      throw StateError(
        'BattlePseudoWeatherState cannot be decremented below 1 remaining turn.',
      );
    }
    return BattlePseudoWeatherState(
      id: id,
      remainingTurns: remainingTurns - 1,
    );
  }
}

/// État de champ observable par le moteur battle.
///
/// BE9 ajoute ce contrat explicitement dans l'état battle pour deux raisons :
/// - la météo / Trick Room cessent d'être des détails cachés de résolution ;
/// - le runtime et les tests peuvent observer honnêtement ce qui est actif.
///
/// Frontière volontaire :
/// - une météo active maximum ;
/// - un pseudoWeather actif maximum ;
/// - aucun side state, aucun slot state, aucune structure vide "pour plus tard".
final class BattleFieldState {
  const BattleFieldState({
    this.weather,
    this.pseudoWeather,
  });

  final BattleWeatherState? weather;
  final BattlePseudoWeatherState? pseudoWeather;

  bool get hasAny => weather != null || pseudoWeather != null;

  bool isWeatherActive(BattleWeatherId id) => weather?.id == id;

  bool isPseudoWeatherActive(BattlePseudoWeatherId id) =>
      pseudoWeather?.id == id;

  BattleFieldState withWeather(BattleWeatherState? value) {
    if (weather == value) {
      return this;
    }
    return BattleFieldState(
      weather: value,
      pseudoWeather: pseudoWeather,
    );
  }

  BattleFieldState withPseudoWeather(BattlePseudoWeatherState? value) {
    if (pseudoWeather == value) {
      return this;
    }
    return BattleFieldState(
      weather: weather,
      pseudoWeather: value,
    );
  }
}

/// Taxonomie minimale des événements de champ visibles pendant un tour.
///
/// BE9 évite volontairement deux dérives :
/// - gonfler `BattleMoveExecution` avec des booléens de météo/room ;
/// - créer un event bus générique pour tout le moteur.
///
/// Une petite liste sœur dédiée suffit pour garder le champ observable.
enum BattleFieldEventKind {
  weatherSet,
  weatherResidualDamage,
  weatherExpired,
  pseudoWeatherSet,
  pseudoWeatherCleared,
  pseudoWeatherExpired,
}

/// Trace minimale d'un événement de champ pendant un tour.
///
/// Le payload reste borné aux besoins réels de BE9 :
/// - quel champ a été posé / retiré / expiré ;
/// - quel combattant subit un résiduel météo ;
/// - quel move l'a éventuellement déclenché.
final class BattleFieldEvent {
  const BattleFieldEvent.weatherSet({
    required this.weather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.weatherSet,
        pseudoWeather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.weatherResidualDamage({
    required this.weather,
    required this.targetSlot,
    required this.damage,
  })  : kind = BattleFieldEventKind.weatherResidualDamage,
        pseudoWeather = null,
        sourceMoveId = null;

  const BattleFieldEvent.weatherExpired({
    required this.weather,
  })  : kind = BattleFieldEventKind.weatherExpired,
        pseudoWeather = null,
        sourceMoveId = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherSet({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherSet,
        weather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherCleared({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherCleared,
        weather = null,
        targetSlot = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherExpired({
    required this.pseudoWeather,
  })  : kind = BattleFieldEventKind.pseudoWeatherExpired,
        weather = null,
        sourceMoveId = null,
        targetSlot = null,
        damage = null;

  final BattleFieldEventKind kind;
  final BattleWeatherId? weather;
  final BattlePseudoWeatherId? pseudoWeather;
  final String? sourceMoveId;

  /// Slot explicitement affecté quand l'événement de champ touche un combattant.
  ///
  /// Phase G évite ici un faux contrat générique :
  /// - aujourd'hui seul le résiduel météo cible un combattant ;
  /// - les autres événements de champ restent globaux et gardent `null`.
  final BattleSlotRef? targetSlot;

  BattleSideId? get targetSide => targetSlot?.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  String? get target => targetSide?.actorId;

  final int? damage;
}

```

### `packages/map_battle/lib/src/battle_resolution.dart`

```dart
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_state.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
import 'battle_switch.dart';
import 'battle_volatile.dart';

/// Résultat d'un tour de combat.
///
/// Contient les actions jouées et leurs exécutions.
/// Utilisé pour afficher le déroulement du tour au joueur.
class BattleTurnResult {
  /// Crée un résultat de tour.
  ///
  /// [playerAction] - L'action jouée par le joueur.
  /// [enemyAction] - L'action jouée par l'ennemi.
  /// [executions] - La liste des exécutions d'attaques (dans l'ordre).
  /// [statusEvents] - Les événements de statut/résiduel visibles du tour.
  /// [volatileEvents] - Les événements volatiles BE8 visibles du tour.
  /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
  /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
    this.switchEvents = const <BattleSwitchEvent>[],
    this.timeline = const <BattleTurnEvent>[],
  });

  /// L'action jouée par le joueur.
  final BattleAction playerAction;

  /// L'action jouée par l'ennemi.
  final BattleAction enemyAction;

  /// La liste des exécutions d'attaques.
  ///
  /// Ordonnées selon l'ordre de résolution (déterministe).
  /// Depuis BE3 :
  /// - priorité décroissante ;
  /// - puis vitesse effective décroissante ;
  /// - puis tie-break déterministe explicite.
  final List<BattleMoveExecution> executions;

  /// Les événements de statut visibles pendant ce tour.
  ///
  /// BE7 ajoute cette trace minimale pour ne plus mentir sur deux axes :
  /// - l'application d'un statut majeur ne doit pas être une mutation muette ;
  /// - les résiduels de fin de tour ne doivent pas retirer des PV sans trace.
  final List<BattleStatusEvent> statusEvents;

  /// Les événements volatiles visibles pendant ce tour.
  ///
  /// BE8 les sépare volontairement de `statusEvents` :
  /// - `Protect`, la recharge et la charge sur deux tours n'ont pas la même
  ///   sémantique que les statuts majeurs ;
  /// - les entasser dans `BattleMoveExecution` ferait grossir ce contrat avec
  ///   des booléens croisés peu lisibles ;
  /// - une petite liste sœur garde la trace honnête sans créer un event bus.
  final List<BattleVolatileEvent> volatileEvents;

  /// Les événements de champ visibles pendant ce tour.
  ///
  /// BE9 les sépare volontairement du reste :
  /// - la météo et Trick Room sont désormais de vrais états moteur ;
  /// - les entasser dans `statusEvents` ou `volatileEvents` brouillerait les
  ///   invariants métier de chaque couche ;
  /// - une petite troisième liste suffit à garder le champ observable sans
  ///   ouvrir un journal universel.
  final List<BattleFieldEvent> fieldEvents;

  /// Les événements de switch / remplacement visibles pendant ce tour.
  ///
  /// BE10 les sépare volontairement du reste :
  /// - un switch n'est ni un statut majeur, ni un volatile BE8, ni un
  ///   événement de champ ;
  /// - le runtime/UI a besoin de distinguer un remplacement forcé d'une simple
  ///   exécution de move ;
  /// - cette petite liste sœur suffit à garder l'état observable sans ouvrir
  ///   de journal universel.
  final List<BattleSwitchEvent> switchEvents;

  /// Chronologie ordonnée du tour telle que réellement résolue par le moteur.
  ///
  /// BE10A ajoute cette source de vérité pour arrêter un nouveau mensonge :
  /// - les buckets `executions` / `statusEvents` / `volatileEvents` /
  ///   `fieldEvents` / `switchEvents` restent utiles pour les tests ciblés
  ///   et la compatibilité locale ;
  /// - mais ils ne peuvent pas, à eux seuls, exprimer l'ordre croisé entre
  ///   un switch, une exécution d'attaque, un résiduel puis un remplacement ;
  /// - le runtime/overlay ne doit donc plus reconstruire la chronologie avec
  ///   un tri heuristique de buckets.
  ///
  /// Frontière volontaire :
  /// - ce n'est pas un event bus générique ;
  /// - on transporte uniquement les cinq familles déjà réellement supportées ;
  /// - l'ordre est celui construit pendant la résolution réelle du tour.
  final List<BattleTurnEvent> timeline;
}

/// Entrée de chronologie ordonnée d'un tour.
///
/// Ce contrat reste strictement local à la restitution du tour :
/// - il ne remplace pas les buckets historiques ;
/// - il ne devient pas un journal universel du moteur ;
/// - il sert uniquement à conserver un ordre causal honnête entre les familles
///   d'événements déjà réellement supportées.
sealed class BattleTurnEvent {
  const BattleTurnEvent();
}

final class BattleTurnExecutionEvent extends BattleTurnEvent {
  const BattleTurnExecutionEvent(this.execution);

  final BattleMoveExecution execution;
}

final class BattleTurnStatusEvent extends BattleTurnEvent {
  const BattleTurnStatusEvent(this.event);

  final BattleStatusEvent event;
}

final class BattleTurnVolatileEvent extends BattleTurnEvent {
  const BattleTurnVolatileEvent(this.event);

  final BattleVolatileEvent event;
}

final class BattleTurnFieldEvent extends BattleTurnEvent {
  const BattleTurnFieldEvent(this.event);

  final BattleFieldEvent event;
}

final class BattleTurnSwitchEvent extends BattleTurnEvent {
  const BattleTurnSwitchEvent(this.event);

  final BattleSwitchEvent event;
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
///
/// Phase G élargit volontairement ce contrat sur un point précis :
/// - l'exécution ne doit plus être seulement observable via des chaînes
///   `"player"` / `"enemy"` / `"field"` ;
/// - le moteur a désormais une vraie topologie singles (`side` / `slot`) ;
/// - la trace de résolution doit donc porter cette topologie elle aussi.
///
/// Garde-fou de scope :
/// - on n'ouvre pas un système de targeting riche ;
/// - on ne porte toujours que le sous-ensemble réellement supporté :
///   cible combattant active ou cible field ;
/// - les getters stringly-typed restent comme seam de compatibilité local.
enum BattleMoveExecutionTargetKind {
  combatant,
  field,
}

class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attackerSlot] - Le slot qui a réellement exécuté l'attaque.
  /// [move] - L'attaque utilisée.
  /// [targetKind] - La famille de cible réellement résolue.
  /// [targetSlot] - Le slot ciblé quand [targetKind] vaut `combatant`.
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attackerSlot,
    required this.move,
    required this.targetKind,
    this.targetSlot,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  }) : assert(
          (targetKind == BattleMoveExecutionTargetKind.combatant &&
                  targetSlot != null) ||
              (targetKind == BattleMoveExecutionTargetKind.field &&
                  targetSlot == null),
          'BattleMoveExecution targetKind/targetSlot must describe either a combatant slot or the field.',
        );

  /// Slot attaquant réellement résolu par le moteur.
  ///
  /// En singles Phase D/F :
  /// - il s'agit encore toujours du slot actif `0` d'un side ;
  /// - mais l'exécution arrête de mentir en faisant comme si la topologie
  ///   n'existait pas.
  final BattleSlotRef attackerSlot;

  /// Side de l'attaquant.
  BattleSideId get attackerSide => attackerSlot.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Ce getter n'est plus la source de vérité ; il dérive désormais du slot.
  String get attacker => attackerSide.actorId;

  /// L'attaque utilisée.
  final BattleMove move;

  /// Famille de cible réellement consommée par cette exécution.
  final BattleMoveExecutionTargetKind targetKind;

  /// Slot ciblé quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - `null` signifie uniquement "le move vise le field" ;
  /// - on ne crée ni targeting riche, ni tableau de cibles multiples.
  final BattleSlotRef? targetSlot;

  /// Side ciblé quand l'exécution vise un combattant.
  BattleSideId? get targetSide => targetSlot?.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  ///
  /// Valeurs dérivées :
  /// - `"player"` / `"enemy"` pour une cible combattant ;
  /// - `"field"` pour une cible field.
  String get target => switch (targetKind) {
        BattleMoveExecutionTargetKind.combatant => targetSlot!.side.actorId,
        BattleMoveExecutionTargetKind.field => 'field',
      };

  /// Les dégâts infligés.
  ///
  /// Après M8 puis BE4 :
  /// - un move de statut touché peut infliger `0` dégât ;
  /// - un move qui miss inflige aussi `0` dégât ;
  /// - un move de dégâts standards part toujours de `move.power` ;
  /// - des multiplicateurs simples issus des étages de stats peuvent modifier
  ///   ce montant ;
  /// - BE5 y ajoute STAB et efficacité de type ;
  /// - on reste néanmoins très loin d'une formule Pokémon complète.
  final int damage;

  /// true si le move a réellement touché.
  ///
  /// BE4 l'ajoute pour arrêter un autre mensonge silencieux :
  /// - `damage == 0` ne distingue pas un miss d'un move de statut ;
  /// - la trace d'exécution doit donc porter explicitement le hit/miss ;
  /// - on évite ainsi de forcer l'UI/runtime à deviner l'issue depuis un
  ///   contrat trop pauvre.
  final bool didHit;

  /// true si le move a réellement déclenché un critique.
  ///
  /// BE6 ajoute ce flag pour éviter une nouvelle perte de vérité :
  /// - un critique ne doit pas être deviné indirectement depuis les dégâts ;
  /// - le runtime/UI doit pouvoir distinguer un simple hit d'un vrai crit ;
  /// - un miss, une immunité ou un move de statut gardent toujours `false`.
  final bool didCrit;

  /// Multiplicateur critique réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE6 :
  /// - `1.5` sur un critique déclenché ;
  /// - `1.0` sinon.
  ///
  /// Ce champ reste volontairement petit :
  /// - il documente l'effet réellement appliqué ;
  /// - il n'ouvre pas un système complet de règles avancées de critique.
  final double criticalMultiplier;

  /// Multiplicateur STAB réellement appliqué à ce move.
  ///
  /// Valeurs attendues dans BE5 :
  /// - `1.5` si l'attaquant partage le type du move ;
  /// - `1.0` sinon ;
  /// - `1.0` aussi sur les vieux call sites battle qui n'ont pas de typing.
  final double stabMultiplier;

  /// Multiplicateur d'efficacité de type réellement appliqué.
  ///
  /// Valeurs typiques BE5 :
  /// - `2.0`, `4.0` pour les faiblesses ;
  /// - `0.5`, `0.25` pour les résistances ;
  /// - `0.0` pour une immunité ;
  /// - `1.0` pour un cas neutre ou pour un vieux setup battle sans typing.
  ///
  /// Important :
  /// - `didHit == true` et `typeEffectivenessMultiplier == 0.0` signifient
  ///   "le move a bien passé le hit check, mais la cible y est immunisée" ;
  /// - cela évite de confondre immunité, miss et move de statut.
  final double typeEffectivenessMultiplier;
}

/// Type de résultat final d'un combat.
enum BattleOutcomeType {
  /// Le joueur a gagné (ennemi K.O.).
  victory,

  /// Le joueur a perdu (joueur K.O.).
  defeat,

  /// Le joueur a fui avec succès.
  runaway,

  /// Le joueur a capturé avec succès un Pokémon sauvage.
  ///
  /// Le lot 13 garde ce contrat volontairement petit :
  /// - l'issue termine immédiatement le combat ;
  /// - elle ne porte pas de formule de capture canonique ;
  /// - le runtime se charge ensuite d'écrire réellement le Pokémon capturé
  ///   dans la party/save du joueur.
  captured,
}

/// Résultat final d'un combat.
///
/// Contient le type de résultat et l'état final du combat.
/// Utilisé par le runtime pour déterminer les actions post-combat
/// (marquage trainer defeated, retour overworld, etc.).
class BattleOutcome {
  /// Crée un résultat de combat.
  ///
  /// [type] - Le type de résultat (victoire, défaite, fuite).
  /// [finalState] - L'état final du combat.
  const BattleOutcome({required this.type, required this.finalState});

  /// Le type de résultat.
  final BattleOutcomeType type;

  /// L'état final du combat.
  final BattleState finalState;

  /// true si le joueur a gagné.
  bool get isVictory => type == BattleOutcomeType.victory;

  /// true si le joueur a perdu.
  bool get isDefeat => type == BattleOutcomeType.defeat;

  /// true si le joueur a fui.
  bool get isRunaway => type == BattleOutcomeType.runaway;

  /// true si le joueur a capturé le Pokémon sauvage.
  bool get isCaptured => type == BattleOutcomeType.captured;
}

```

### `packages/map_battle/lib/src/battle_session.dart`

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
      BattleMoveTarget.field => null,
      BattleMoveTarget.opponent || BattleMoveTarget.unspecified => opponentSlot,
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

### `packages/map_battle/lib/src/battle_status.dart`

```dart
import 'battle_topology.dart';

/// Identifiant minimal de statut majeur réellement supporté par le moteur.
///
/// BE7 ouvre volontairement un seul sous-ensemble :
/// - `par`
/// - `brn`
/// - `psn`
/// - `tox`
///
/// Tout le reste reste explicitement hors scope :
/// - pas de `slp`
/// - pas de `frz`
/// - pas de confusion
/// - pas de système générique de volatiles.
enum BattleMajorStatusId {
  par,
  brn,
  psn,
  tox,
}

/// État minimal d'un statut majeur porté par un combattant battle.
///
/// Ce contrat reste volontairement petit :
/// - il porte seulement quel statut majeur est actif ;
/// - il ajoute un compteur toxique local pour `tox` ;
/// - il n'essaie pas d'anticiper un futur système de statuts générique.
///
/// Le compteur toxique suit une règle très simple :
/// - `tox` commence à `1` ;
/// - le résiduel de fin de tour consomme cette valeur ;
/// - si le combattant survit, on l'incrémente pour le tour suivant.
final class BattleMajorStatusState {
  const BattleMajorStatusState.par()
      : id = BattleMajorStatusId.par,
        toxicCounter = 0;

  const BattleMajorStatusState.brn()
      : id = BattleMajorStatusId.brn,
        toxicCounter = 0;

  const BattleMajorStatusState.psn()
      : id = BattleMajorStatusId.psn,
        toxicCounter = 0;

  const BattleMajorStatusState.tox({
    this.toxicCounter = 1,
  })  : assert(toxicCounter >= 1),
        id = BattleMajorStatusId.tox;

  final BattleMajorStatusId id;

  /// Compteur local du poison toxique.
  ///
  /// Pour les autres statuts, cette valeur reste à `0` et n'a aucune
  /// sémantique métier.
  final int toxicCounter;

  bool get isToxic => id == BattleMajorStatusId.tox;

  BattleMajorStatusState incrementToxicCounter() {
    if (!isToxic) {
      return this;
    }
    return BattleMajorStatusState.tox(
      toxicCounter: toxicCounter + 1,
    );
  }

  /// Réinitialise l'état local qui ne doit pas survivre à un switch-out.
  ///
  /// BE10 garde une politique très étroite :
  /// - `par`, `brn`, `psn` restent inchangés ;
  /// - `tox` reste bien `tox` ;
  /// - mais sa progression locale repart à `1` quand le Pokémon quitte puis
  ///   revient sur le terrain.
  BattleMajorStatusState resetOnSwitchOut() {
    if (!isToxic) {
      return this;
    }
    return const BattleMajorStatusState.tox();
  }
}

/// Effet battle minimal pour `applyStatus`.
///
/// Le bridge runtime -> battle traduit `PokemonMoveEffect.applyStatus` vers ce
/// contrat local seulement quand le sous-ensemble BE7 est réellement
/// exécutable. Il ne transporte pas la totalité du payload canonique :
/// - scope `target` seulement ;
/// - `chancePercent == null` pour un status garanti sur hit ;
/// - `chancePercent` entre 1 et 100 pour un status probabiliste.
final class BattleMoveMajorStatusEffect {
  const BattleMoveMajorStatusEffect({
    required this.status,
    this.chancePercent,
  }) : assert(
          chancePercent == null || (chancePercent >= 1 && chancePercent <= 100),
          'BattleMoveMajorStatusEffect chancePercent must be null or between 1 and 100.',
        );

  final BattleMajorStatusId status;
  final int? chancePercent;
}

/// Petite taxonomie des événements de statut visibles dans le résultat de tour.
///
/// BE7 ne crée pas un event bus général. On garde seulement ce qui évite une
/// mutation silencieuse :
/// - application d'un statut majeur ;
/// - blocage parce qu'un statut majeur existe déjà ;
/// - impossibilité d'agir à cause de la paralysie ;
/// - dégâts résiduels de fin de tour.
enum BattleStatusEventKind {
  applied,
  blockedExistingMajorStatus,
  preventedAction,
  residualDamage,
}

/// Trace minimale d'un événement de statut pendant un tour.
///
/// Ce contrat existe pour deux raisons :
/// - éviter que les statuts/résiduels modifient l'état sans trace ;
/// - rester assez petit pour ne pas ressembler à un journal d'événements
///   générique du moteur.
final class BattleStatusEvent {
  const BattleStatusEvent.applied({
    required this.targetSlot,
    required this.status,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.applied,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.blockedExistingMajorStatus({
    required this.targetSlot,
    required this.status,
    required this.existingStatus,
    required this.sourceMoveId,
  })  : kind = BattleStatusEventKind.blockedExistingMajorStatus,
        damage = null,
        toxicCounter = null;

  const BattleStatusEvent.preventedAction({
    required this.targetSlot,
    required this.status,
  })  : kind = BattleStatusEventKind.preventedAction,
        sourceMoveId = null,
        damage = null,
        toxicCounter = null,
        existingStatus = null;

  const BattleStatusEvent.residualDamage({
    required this.targetSlot,
    required this.status,
    required this.damage,
    this.toxicCounter,
  })  : kind = BattleStatusEventKind.residualDamage,
        sourceMoveId = null,
        existingStatus = null;

  /// Slot ciblé par l'événement.
  ///
  /// Phase G élargit volontairement le contrat ici :
  /// - les statuts majeurs ciblent encore toujours un combattant actif ;
  /// - mais ils cessent d'être attachés à une simple chaîne `"player"` /
  ///   `"enemy"` alors que le moteur porte déjà une vraie topologie.
  final BattleSlotRef targetSlot;

  /// Side ciblé par l'événement.
  BattleSideId get targetSide => targetSlot.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  String get target => targetSide.actorId;

  final BattleStatusEventKind kind;
  final BattleMajorStatusId status;
  final String? sourceMoveId;
  final int? damage;
  final int? toxicCounter;
  final BattleMajorStatusId? existingStatus;
}

```

### `packages/map_battle/lib/src/battle_volatile.dart`

```dart
import 'battle_topology.dart';

/// Identifiant minimal de volatile réellement supporté par BE8.
///
/// On n'ouvre volontairement pas une taxonomie générique de volatiles :
/// - BE8 n'a besoin que de `protect` ;
/// - le reste (`confusion`, `substitute`, semi-invulnérabilité, etc.) reste
///   explicitement hors scope ;
/// - ce type documente donc un sous-ensemble battle local, pas un futur
///   catalogue complet de mécaniques.
enum BattleVolatileStatusId {
  protect,
}

/// Petit payload battle pour un move à charge sur deux tours.
///
/// BE8 choisit un contrat volontairement minimal :
/// - `chargeStateId` reste optionnel, uniquement pour garder une trace lisible
///   quand la donnée canonique en fournit une ;
/// - aucun système générique de "phases de move" n'est ouvert ;
/// - ce payload n'a de sens que pour `chargeThenStrike`.
final class BattleChargeThenStrikeEffect {
  const BattleChargeThenStrikeEffect({
    this.chargeStateId,
  });

  final String? chargeStateId;
}

/// État local du move actuellement chargé sur le combattant.
///
/// On porte exactement ce que le moteur doit retrouver au tour suivant :
/// - quel slot move doit être rejoué ;
/// - quel move est attendu, pour protéger le moteur d'un état incohérent ;
/// - un éventuel `chargeStateId` lisible pour la trace.
final class BattlePendingChargeState {
  const BattlePendingChargeState({
    required this.moveIndex,
    required this.moveId,
    this.chargeStateId,
  });

  final int moveIndex;
  final String moveId;
  final String? chargeStateId;
}

/// Sous-état volatile battle local du combattant.
///
/// Invariants BE8 :
/// - `protectActive` ne vaut que pour le tour courant et doit être nettoyé en
///   fin de tour ;
/// - `mustRecharge` représente uniquement le tour perdu qui suit certains
///   moves ; il ne doit pas coexister avec un move chargé en attente ;
/// - `pendingCharge` représente uniquement la deuxième moitié d'un move à
///   charge, sans ouvrir une pile de verrous/actions forcées.
final class BattleVolatileState {
  const BattleVolatileState({
    this.protectActive = false,
    this.mustRecharge = false,
    this.pendingCharge,
  }) : assert(
          !(mustRecharge && pendingCharge != null),
          'A battle combatant cannot be both recharging and holding a pending charged move.',
        );

  final bool protectActive;
  final bool mustRecharge;
  final BattlePendingChargeState? pendingCharge;

  bool get hasAny => protectActive || mustRecharge || pendingCharge != null;

  BattleVolatileState withProtectActive(bool value) {
    if (protectActive == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: value,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withMustRecharge(bool value) {
    if (mustRecharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: value,
      pendingCharge: pendingCharge,
    );
  }

  BattleVolatileState withPendingCharge(BattlePendingChargeState? value) {
    if (pendingCharge == value) {
      return this;
    }
    return BattleVolatileState(
      protectActive: protectActive,
      mustRecharge: mustRecharge,
      pendingCharge: value,
    );
  }

  /// Nettoie les marqueurs qui ne doivent jamais survivre au tour suivant.
  ///
  /// BE8 garde cette règle explicite au niveau du petit contrat local :
  /// - `protect` protège uniquement pendant la fenêtre de résolution du tour ;
  /// - ni les résiduels BE7 ni le tour suivant ne doivent encore le voir actif ;
  /// - `mustRecharge` et `pendingCharge`, eux, vivent au-delà du tour et ne
  ///   doivent donc pas être effacés ici.
  BattleVolatileState clearedEndOfTurnFlags() {
    if (!protectActive) {
      return this;
    }
    return BattleVolatileState(
      protectActive: false,
      mustRecharge: mustRecharge,
      pendingCharge: pendingCharge,
    );
  }

  /// Nettoie intégralement les volatiles qui ne survivent pas à un switch-out.
  ///
  /// BE10 choisit ici une règle franche plutôt qu'une taxonomie progressive :
  /// - `Protect` n'a plus aucun sens une fois sur le banc ;
  /// - `mustRecharge` ne doit jamais forcer un Pokémon qui a quitté le terrain ;
  /// - `pendingCharge` ne doit jamais survivre à un switch ;
  /// - on revient donc à l'état vide, sans ouvrir un système générique de
  ///   "volatiles persistants".
  BattleVolatileState clearedOnSwitchOut() {
    if (!hasAny) {
      return this;
    }
    return const BattleVolatileState();
  }
}

/// Taxonomie minimale des événements volatiles visibles dans un tour.
///
/// BE8 n'étend pas `statusEvents` pour tout mélanger :
/// - les statuts majeurs et les volatiles n'ont pas la même temporalité ;
/// - `protect`, `mustRecharge` et `chargeThenStrike` ont besoin d'une trace
///   propre sans grossir `BattleMoveExecution` jusqu'à l'illisible ;
/// - on garde donc une petite liste sœur, bornée au lot BE8.
enum BattleVolatileEventKind {
  protectActivated,
  protectBlocked,
  protectBroken,
  rechargeRequired,
  rechargeTurnSpent,
  chargeStarted,
  chargeReleased,
}

/// Trace minimale d'un événement volatile pendant un tour.
///
/// Le contrat reste volontairement petit :
/// - pas de bus d'événements ;
/// - pas de payload dynamique ;
/// - juste les champs nécessaires pour expliquer ce qu'un tour BE8 a vraiment
///   fait ou empêché.
final class BattleVolatileEvent {
  const BattleVolatileEvent.protectActivated({
    required this.actorSlot,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectActivated,
        targetSlot = null,
        chargeStateId = null;

  const BattleVolatileEvent.protectBlocked({
    required this.actorSlot,
    required this.targetSlot,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBlocked,
        chargeStateId = null;

  const BattleVolatileEvent.protectBroken({
    required this.actorSlot,
    required this.targetSlot,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.protectBroken,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeRequired({
    required this.actorSlot,
    required this.sourceMoveId,
  })  : kind = BattleVolatileEventKind.rechargeRequired,
        targetSlot = null,
        chargeStateId = null;

  const BattleVolatileEvent.rechargeTurnSpent({
    required this.actorSlot,
  })  : kind = BattleVolatileEventKind.rechargeTurnSpent,
        targetSlot = null,
        sourceMoveId = null,
        chargeStateId = null;

  const BattleVolatileEvent.chargeStarted({
    required this.actorSlot,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeStarted,
        targetSlot = null;

  const BattleVolatileEvent.chargeReleased({
    required this.actorSlot,
    required this.sourceMoveId,
    this.chargeStateId,
  })  : kind = BattleVolatileEventKind.chargeReleased,
        targetSlot = null;

  /// Slot qui a provoqué l'événement.
  ///
  /// Phase G garde ce contrat volontairement petit :
  /// - on ne crée pas une taxonomie générique de sources ;
  /// - on exprime seulement le slot actif singles réellement impliqué.
  final BattleSlotRef actorSlot;

  /// Cible explicite quand l'événement a une cible distincte.
  final BattleSlotRef? targetSlot;

  BattleSideId get actorSide => actorSlot.side;
  BattleSideId? get targetSide => targetSlot?.side;

  /// Compatibilité locale pour les surfaces encore stringly-typed.
  String get actor => actorSide.actorId;
  String? get target => targetSide?.actorId;

  final BattleVolatileEventKind kind;
  final String? sourceMoveId;
  final String? chargeStateId;
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
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
      expect(
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
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
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.enemy),
        targetSlot: const BattleSlotRef.active(BattleSideId.player),
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isTrue);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBlocked),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(
        result.volatileEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.enemy),
        targetSlot: const BattleSlotRef.active(BattleSideId.player),
        attacker: attacker,
        defender: defender,
      );

      expect(result.blockedByProtect, isFalse);
      expect(result.defender.volatileState.protectActive, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.protectBroken),
      );
      expect(
        result.volatileEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
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
      expect(
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
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
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        attackerSlot: const BattleSlotRef.active(BattleSideId.player),
        targetSlot: const BattleSlotRef.active(BattleSideId.enemy),
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
      expect(result.fieldEvents.single.targetSlot, isNull);
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
        combatantSlot: const BattleSlotRef.active(BattleSideId.player),
        combatant: combatant,
      );

      expect(result.combatant.volatileState.mustRecharge, isFalse);
      expect(
        result.volatileEvents.single.kind,
        equals(BattleVolatileEventKind.rechargeTurnSpent),
      );
      expect(
        result.volatileEvents.single.actorSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
        result.statusEvents.single.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
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
      expect(
        result.fieldEvents
            .where(
              (event) =>
                  event.kind == BattleFieldEventKind.weatherResidualDamage,
            )
            .map((event) => event.targetSlot)
            .toList(growable: false),
        equals(<BattleSlotRef?>[
          const BattleSlotRef.active(BattleSideId.player),
          const BattleSlotRef.active(BattleSideId.enemy),
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

### `packages/map_battle/test/battle_field_test.dart`

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
      expect(
        residualEvent.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(residualEvent.damage, equals(6));
      final timeline = afterTurn.state.currentTurn!.timeline;
      final enemyActionIndex = timeline.lastIndexWhere(
        (event) =>
            event is BattleTurnExecutionEvent &&
            event.execution.attacker == 'enemy',
      );
      final enemyExecution =
          afterTurn.state.currentTurn!.executions.singleWhere(
        (execution) => execution.attacker == 'enemy',
      );
      expect(
        enemyExecution.attackerSlot,
        equals(const BattleSlotRef.active(BattleSideId.enemy)),
      );
      expect(
        enemyExecution.targetSlot,
        equals(const BattleSlotRef.active(BattleSideId.player)),
      );
      expect(
        enemyExecution.targetKind,
        equals(BattleMoveExecutionTargetKind.combatant),
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

### `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

```dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

/// Retourne le prompt de décision à afficher pour la requête courante.
///
/// Phase C utilise cette petite fonction pure pour une raison concrète :
/// - l'overlay doit désormais afficher le *type* de requête demandé par le
///   moteur, pas déduire ce type depuis une liste plate de choix ;
/// - garder ce formatage dans un helper pur permet aussi de le verrouiller en
///   test sans devoir piloter tout le composant Flame ;
/// - on reste très loin d'un système de présentation générique.
String buildBattleDecisionPromptForOverlay(BattleDecisionRequest request) {
  return switch (request) {
    BattleTurnChoiceRequest() => 'Que doit faire le joueur ?',
    BattleForcedReplacementRequest() =>
      'Le joueur doit remplacer son Pokémon K.O.',
    BattleContinueRequest() => 'Le joueur doit continuer un tour forcé',
    BattleWaitRequest(:final reason) => switch (reason) {
        BattleWaitReason.battleFinished => 'Combat terminé',
        BattleWaitReason.resolvingTurn => 'Résolution du tour en cours',
        BattleWaitReason.activeFaintedWithoutReplacement =>
          'Aucun remplaçant disponible',
        BattleWaitReason.noLegalChoice => 'Aucune décision légale disponible',
      },
  };
}

/// Construit les lignes de restitution d'un tour pour l'overlay runtime.
///
/// BE10A centralise ici la restitution textuelle pour une raison précise :
/// - l'overlay ne doit plus réinventer l'ordre du tour en triant des buckets ;
/// - la vraie source de vérité est désormais `BattleTurnResult.timeline` ;
/// - cette fonction garde donc la surface runtime alignée sur la chronologie
///   réellement produite par le moteur battle.
///
/// Garde-fou volontaire :
/// - si un `BattleTurnResult` porte encore des buckets non vides sans
///   chronologie ordonnée, on échoue explicitement ;
/// - mieux vaut un seam bruyant qu'une UI qui raconte un ordre faux.
List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
  if (turnResult.timeline.isEmpty &&
      (turnResult.executions.isNotEmpty ||
          turnResult.statusEvents.isNotEmpty ||
          turnResult.volatileEvents.isNotEmpty ||
          turnResult.fieldEvents.isNotEmpty ||
          turnResult.switchEvents.isNotEmpty)) {
    throw StateError(
      'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
    );
  }

  final lines = <String>[];
  for (final event in turnResult.timeline) {
    switch (event) {
      case BattleTurnExecutionEvent(:final execution):
        final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
        lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts',
        );
      case BattleTurnStatusEvent(:final event):
        lines.add(_formatOverlayStatusEvent(event));
      case BattleTurnVolatileEvent(:final event):
        lines.add(_formatOverlayVolatileEvent(event));
      case BattleTurnFieldEvent(:final event):
        lines.add(_formatOverlayFieldEvent(event));
      case BattleTurnSwitchEvent(:final event):
        lines.add(_formatOverlaySwitchEvent(event));
    }
  }

  return List<String>.unmodifiable(lines);
}

String _formatOverlaySwitchEvent(BattleSwitchEvent event) {
  final actor = _overlayCombatantLabelForSide(event.side);
  return switch (event.kind) {
    BattleSwitchEventKind.switched => event.wasForced
        ? '$actor remplace ${event.fromSpeciesId} par ${event.toSpeciesId}'
        : '$actor switch de ${event.fromSpeciesId} vers ${event.toSpeciesId}',
    BattleSwitchEventKind.replacementRequired =>
      '$actor doit remplacer ${event.fromSpeciesId} K.O.',
  };
}

String _formatOverlayStatusEvent(BattleStatusEvent event) {
  final actor = _overlayCombatantLabelForSide(event.targetSide);
  final status = event.status.name.toUpperCase();
  return switch (event.kind) {
    BattleStatusEventKind.applied =>
      '$actor reçoit le statut $status (${event.sourceMoveId})',
    BattleStatusEventKind.blockedExistingMajorStatus =>
      '$actor garde déjà ${event.existingStatus!.name.toUpperCase()} '
          'et ignore $status',
    BattleStatusEventKind.preventedAction =>
      '$actor ne peut pas agir à cause de $status',
    BattleStatusEventKind.residualDamage =>
      '$actor subit ${event.damage} dégâts résiduels ($status'
          '${event.toxicCounter == null ? '' : ', compteur ${event.toxicCounter}'}'
          ')',
  };
}

String _formatOverlayVolatileEvent(BattleVolatileEvent event) {
  final actor = _overlayCombatantLabelForSide(event.actorSide);
  final target = event.targetSide == null
      ? null
      : _overlayCombatantLabelForSide(event.targetSide!);

  return switch (event.kind) {
    BattleVolatileEventKind.protectActivated => '$actor active Protect',
    BattleVolatileEventKind.protectBlocked =>
      '${target ?? 'La cible'} bloque l’attaque avec Protect',
    BattleVolatileEventKind.protectBroken =>
      '$actor perce Protect sur ${target ?? 'la cible'}',
    BattleVolatileEventKind.rechargeRequired =>
      '$actor doit recharger au tour suivant',
    BattleVolatileEventKind.rechargeTurnSpent =>
      '$actor passe son tour pour recharger',
    BattleVolatileEventKind.chargeStarted =>
      '$actor commence à charger ${event.sourceMoveId ?? 'son attaque'}',
    BattleVolatileEventKind.chargeReleased =>
      '$actor libère ${event.sourceMoveId ?? 'son attaque chargée'}',
  };
}

String _formatOverlayFieldEvent(BattleFieldEvent event) {
  return switch (event.kind) {
    BattleFieldEventKind.weatherSet =>
      'Le champ passe à ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherResidualDamage =>
      '${_overlayCombatantLabelForSide(event.targetSide!)} subit ${event.damage} dégâts de ${_overlayWeatherLabel(event.weather!)}',
    BattleFieldEventKind.weatherExpired =>
      '${_overlayWeatherLabel(event.weather!)} prend fin',
    BattleFieldEventKind.pseudoWeatherSet =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} devient actif',
    BattleFieldEventKind.pseudoWeatherCleared =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
    BattleFieldEventKind.pseudoWeatherExpired =>
      '${_overlayPseudoWeatherLabel(event.pseudoWeather!)} prend fin',
  };
}

String _overlayCombatantLabelForSide(BattleSideId side) {
  return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
}

String _overlayWeatherLabel(BattleWeatherId weather) {
  return switch (weather) {
    BattleWeatherId.rain => 'la pluie',
    BattleWeatherId.sandstorm => 'la tempête de sable',
  };
}

String _overlayPseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
  return switch (pseudoWeather) {
    BattlePseudoWeatherId.trickRoom => 'Trick Room',
  };
}

/// Composant UI d'overlay de combat.
///
/// Affiche l'état courant du combat et permet au joueur de choisir une action.
/// Ne contient AUCUNE logique métier de combat — pure UI.
///
/// La logique métier est dans `map_battle` (BattleSession).
/// Ce composant se contente de :
/// - Afficher les PV des combattants
/// - Afficher les choix disponibles
/// - Notifier le runtime du choix du joueur via [onPlayerChoice]
///
/// **Interaction** : L'utilisateur peut cliquer sur un choix pour le sélectionner.
/// Le clic appelle [onPlayerChoice] avec le choix correspondant.
///
/// **IMPORTANT** : Ce composant stocke une référence mutable vers la session
/// courante. Quand le runtime appelle [updateState()], la session interne
/// est mise à jour pour refléter le nouvel état. Toutes les méthodes d'affichage
/// lisent [session] qui est donc toujours à jour.
class BattleOverlayComponent extends PositionComponent with TapCallbacks {
  /// Crée un overlay de combat.
  ///
  /// [session] - La session de combat courante (état + API).
  /// [viewportSize] - La taille de la viewport pour centrer le panneau.
  /// [onPlayerChoice] - Callback appelé quand le joueur fait un choix.
  BattleOverlayComponent({
    required BattleSession session,
    required Vector2 viewportSize,
    required this.onPlayerChoice,
  })  : _session = session,
        super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 97,
        );

  /// La session de combat courante.
  ///
  /// **Mutable** : mise à jour par [updateState()] pour refléter le nouvel état.
  /// Toutes les méthodes d'affichage lisent cette propriété, donc l'UI est
  /// toujours synchronisée avec l'état réel du combat.
  BattleSession _session;

  /// Callback appelé quand le joueur fait un choix.
  ///
  /// Le runtime doit appeler `session.applyChoice(choice)` pour appliquer le choix.
  final void Function(PlayerBattleChoice choice) onPlayerChoice;

  /// Référence vers le panneau principal (pour mise à jour dynamique).
  PositionComponent? _panel;

  /// Composants de texte pour les PV (pour mise à jour dynamique).
  TextComponent? _playerHpText;
  TextComponent? _enemyHpText;
  TextComponent? _choicesTitleText;

  /// Composant de texte pour afficher le résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts.
  TextComponent? _turnResultText;

  /// Composants de choix (pour mise à jour dynamique).
  /// Chaque composant est associé à un index de choix.
  final List<_ChoiceComponent> _choiceComponents = [];

  /// Index du choix actuellement sélectionné.
  ///
  /// Utilisé pour la navigation clavier (↑/↓) et pour afficher visuellement
  /// le choix sélectionné avec un style différent.
  ///
  /// Invariant : `_selectedIndex` est toujours entre 0 et `_choiceComponents.length - 1`.
  int _selectedIndex = 0;

  /// Composant de surbrillance pour le choix sélectionné.
  ///
  /// Affiché derrière le choix sélectionné pour le mettre en évidence visuellement.
  RectangleComponent? _selectionHighlight;

  @override
  Future<void> onLoad() async {
    // Fond sombre
    final bg = RectangleComponent(
      size: size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xF20B1020),
      priority: 0,
    );
    add(bg);

    // Panneau principal
    final panelWidth = (size.x - 80).clamp(240.0, 760.0);
    final panelHeight = (size.y - 120).clamp(220.0, 520.0);
    _panel = RectangleComponent(
      size: Vector2(panelWidth, panelHeight),
      position: Vector2((size.x - panelWidth) / 2, (size.y - panelHeight) / 2),
      anchor: Anchor.topLeft,
      paint: Paint()..color = const Color(0xE81A223B),
      priority: 1,
    );
    add(_panel!);

    // Bordure du panneau
    final panelBorder = RectangleComponent(
      size: _panel!.size.clone(),
      anchor: Anchor.topLeft,
      paint: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0x66FFFFFF),
      priority: 2,
    );
    _panel!.add(panelBorder);

    // Titre
    final title = TextComponent(
      text: _getTitleForSession(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 20),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF5F5F5),
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 3,
    );
    _panel!.add(title);

    // PV du joueur
    _playerHpText = TextComponent(
      text: _getPlayerHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 72),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_playerHpText!);

    // PV de l'ennemi
    _enemyHpText = TextComponent(
      text: _getEnemyHpText(),
      anchor: Anchor.topLeft,
      position: Vector2(22, 100),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_enemyHpText!);

    // Titre des choix
    _choicesTitleText = TextComponent(
      text: buildBattleDecisionPromptForOverlay(_session.decisionRequest),
      anchor: Anchor.topLeft,
      position: Vector2(22, 150),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_choicesTitleText!);

    // Choix disponibles
    _renderChoices();

    // Astuce
    final hint = TextComponent(
      text: 'Utilisez les flèches ↑/↓ et E pour choisir',
      anchor: Anchor.bottomLeft,
      position: Vector2(22, panelHeight - 18),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFC4CCDA),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(hint);
  }

  /// Met à jour l'affichage avec un nouvel état de session.
  ///
  /// [newSession] - La nouvelle session avec l'état mis à jour.
  ///
  /// **IMPORTANT** : Cette méthode met à jour [_session] pour que toutes les
  /// méthodes d'affichage (_getChoiceText, etc.) lisent le bon état.
  ///
  /// Cette méthode gère aussi la cohérence de la sélection :
  /// - Si le combat est fini, la sélection est désactivée
  /// - Si la sélection est hors bornes (moins de choix), elle est clampée
  /// - Si un tour est en cours, affiche le résultat du tour (attaques + dégâts)
  void updateState(BattleSession newSession) {
    // Mettre à jour la session interne — CRITIQUE pour la cohérence
    _session = newSession;

    // Mettre à jour les PV
    _playerHpText?.text = _getPlayerHpText();
    _enemyHpText?.text = _getEnemyHpText();
    _choicesTitleText?.text =
        buildBattleDecisionPromptForOverlay(newSession.decisionRequest);

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.decisionRequest.allowedChoices;
      if (_selectedIndex >= choices.length) {
        _selectedIndex = choices.length - 1;
      }
      if (_selectedIndex < 0) {
        _selectedIndex = 0;
      }
      // Re-render pour mettre à jour les choix et la surbrillance
      _renderChoices();
    }
  }

  /// Met à jour l'affichage du résultat du tour en cours.
  ///
  /// Affiche les attaques du joueur et de l'ennemi, ainsi que les dégâts infligés.
  void _updateTurnResult() {
    // Supprimer l'ancien texte de résultat du tour
    _turnResultText?.removeFromParent();
    _turnResultText = null;

    final turnResult = _session.state.currentTurn;
    if (turnResult == null) {
      return;
    }

    final lines = buildBattleTurnLinesForOverlay(turnResult);

    if (lines.isEmpty) {
      return;
    }

    // Afficher le résultat du tour
    _turnResultText = TextComponent(
      text: lines.join('\n'),
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, 130),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      priority: 3,
    );
    _panel!.add(_turnResultText!);
  }

  /// Affiche le résultat final du combat.
  void _showOutcome(BattleOutcome outcome) {
    final outcomeText = switch (outcome.type) {
      BattleOutcomeType.victory => 'Victoire !',
      BattleOutcomeType.defeat => 'Défaite...',
      BattleOutcomeType.runaway => 'Fuite réussie !',
      BattleOutcomeType.captured => 'Capture réussie !',
    };

    final outcomeComponent = TextComponent(
      text: outcomeText,
      anchor: Anchor.topCenter,
      position: Vector2(_panel!.size.x / 2, _panel!.size.y / 2 + 50),
      textRenderer: TextPaint(
        style: TextStyle(
          color: outcome.isVictory || outcome.isCaptured
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
      priority: 10,
    );
    _panel!.add(outcomeComponent);
  }

  /// Affiche les choix disponibles.
  ///
  /// Cette méthode :
  /// 1. Récupère les choix disponibles depuis [_session]
  /// 2. Crée un composant visuel pour chaque choix
  /// 3. Ajoute un composant de surbrillance pour le choix sélectionné
  /// 4. Met à jour [_selectionHighlight] pour le rendu visuel
  void _renderChoices() {
    // Lit [_session] qui est toujours à jour grâce à updateState()
    final request = _session.decisionRequest;
    final choices = request.allowedChoices;
    var y = 190.0;

    // Nettoyer les anciens composants de choix
    for (final component in _choiceComponents) {
      component.removeFromParent();
    }
    _choiceComponents.clear();

    // Nettoyer l'ancienne surbrillance
    _selectionHighlight?.removeFromParent();
    _selectionHighlight = null;

    for (var i = 0; i < choices.length; i++) {
      final choice = choices[i];
      final text = _getChoiceText(request, choice);
      final choiceComponent = _ChoiceComponent(
        choice: choice,
        text: text,
        position: Vector2(22, y),
      );
      _choiceComponents.add(choiceComponent);
      _panel!.add(choiceComponent);

      // Créer la surbrillance pour le choix sélectionné
      if (i == _selectedIndex) {
        _selectionHighlight = RectangleComponent(
          size: Vector2(280, 28),
          position: Vector2(24, y + 2),
          anchor: Anchor.topLeft,
          paint: Paint()
            ..color = const Color(0x40FFFFFF) // Blanc semi-transparent
            ..style = PaintingStyle.fill,
          priority: 2,
        );
        _panel!.add(_selectionHighlight!);
      }

      y += 32;
    }
  }

  /// Retourne le texte à afficher pour un choix.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getChoiceText(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceSwitch) {
      final reserve = _session.state.playerReserve[choice.reserveIndex];
      final isForcedReplacement = request is BattleForcedReplacementRequest;
      final actionLabel = isForcedReplacement ? 'Remplacer par' : 'Switch vers';
      return '↔ $actionLabel ${reserve.speciesId} '
          '(${reserve.currentHp}/${reserve.maxHp} PV)';
    } else if (choice is PlayerBattleChoiceContinue) {
      // Phase C cesse ici d'inférer le sens du tour forcé depuis l'état
      // volatile brut : la vraie source de vérité est désormais la requête.
      if (request case BattleContinueRequest(:final reason)) {
        if (reason == BattleContinueReason.pendingChargeRelease) {
          return 'Continuer (libérer la charge)';
        }
        if (reason == BattleContinueReason.mustRecharge) {
          return 'Continuer (recharge)';
        }
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  /// Retourne le titre pour la session.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getTitleForSession() {
    if (_session.setup.isTrainerBattle) {
      return 'Combat Dresseur';
    }
    return 'Combat Sauvage';
  }

  /// Retourne le texte des PV du joueur.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getPlayerHpText() {
    return 'Joueur (${_session.state.player.speciesId}): '
        '${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi (${_session.state.enemy.speciesId}): '
        '${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
  }

  /// Déplace la sélection vers le haut (choix précédent).
  ///
  /// Si la sélection est déjà au premier choix, reste au premier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionUp() {
    if (_selectedIndex > 0) {
      _selectedIndex--;
      debugPrint('[battle-overlay] moveSelectionUp: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionUp: already at first choice (index=$_selectedIndex)');
    return false;
  }

  /// Déplace la sélection vers le bas (choix suivant).
  ///
  /// Si la sélection est déjà au dernier choix, reste au dernier choix (pas de wrap).
  /// Met à jour visuellement la surbrillance.
  ///
  /// Retourne true si la sélection a changé, false sinon.
  bool moveSelectionDown() {
    if (_selectedIndex < _choiceComponents.length - 1) {
      _selectedIndex++;
      debugPrint(
          '[battle-overlay] moveSelectionDown: new index=$_selectedIndex');
      _renderChoices(); // Re-render pour mettre à jour la surbrillance
      return true;
    }
    debugPrint(
        '[battle-overlay] moveSelectionDown: already at last choice (index=$_selectedIndex, max=${_choiceComponents.length - 1})');
    return false;
  }

  /// Retourne le choix actuellement sélectionné.
  ///
  /// Retourne null si aucun choix n'est disponible.
  PlayerBattleChoice? getSelectedChoice() {
    if (_choiceComponents.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _choiceComponents.length) {
      return null;
    }
    return _choiceComponents[_selectedIndex].choice;
  }

  /// Valide le choix actuellement sélectionné.
  ///
  /// Appelle [onPlayerChoice] avec le choix sélectionné.
  ///
  /// Retourne true si un choix a été validé, false si aucun choix n'est disponible.
  bool validateSelectedChoice() {
    final selectedChoice = getSelectedChoice();
    if (selectedChoice != null) {
      debugPrint(
          '[battle-overlay] validateSelectedChoice: choice=$selectedChoice');
      onPlayerChoice(selectedChoice);
      return true;
    }
    debugPrint('[battle-overlay] validateSelectedChoice: no choice selected');
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Vérifier si un choix a été cliqué
    final tapPos = event.localPosition;
    for (var i = 0; i < _choiceComponents.length; i++) {
      final choiceComponent = _choiceComponents[i];
      if (choiceComponent.containsPoint(tapPos)) {
        // Mettre à jour la sélection visuelle
        _selectedIndex = i;
        _renderChoices();

        // Choix cliqué — notifier le runtime
        onPlayerChoice(choiceComponent.choice);
        return;
      }
    }
  }
}

/// Composant de choix avec référence au choix associé.
///
/// Permet de détecter les clics sur un choix spécifique et de notifier
/// le runtime via [onPlayerChoice].
class _ChoiceComponent extends PositionComponent {
  _ChoiceComponent({
    required this.choice,
    required String text,
    required Vector2 position,
  }) : super(
          size: Vector2(300, 32),
          position: position,
          anchor: Anchor.topLeft,
        ) {
    // Ajouter le texte du choix
    add(TextComponent(
      text: text,
      anchor: Anchor.topLeft,
      position: Vector2.zero(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFE5E9F2),
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    ));
  }

  /// Le choix associé à ce composant.
  final PlayerBattleChoice choice;

  /// Vérifie si un point est dans les bounds de ce composant.
  @override
  bool containsPoint(Vector2 point) {
    return point.x >= position.x &&
        point.x <= position.x + size.x &&
        point.y >= position.y &&
        point.y <= position.y + size.y;
  }
}

```

### `packages/map_runtime/test/battle_overlay_component_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

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
  group('BattleOverlayComponent Phase C decision prompts', () {
    test('uses the request type instead of a flat choice list heuristic', () {
      final freeTurnSession = _session(
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

      expect(
        buildBattleDecisionPromptForOverlay(freeTurnSession.decisionRequest),
        equals('Que doit faire le joueur ?'),
      );

      final forcedReplacementSession = _session(
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
        buildBattleDecisionPromptForOverlay(
          forcedReplacementSession.decisionRequest,
        ),
        equals('Le joueur doit remplacer son Pokémon K.O.'),
      );

      final continueSession = _session(
        player: _combatant(
          speciesId: 'locked_player',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_waitingMove()],
        ),
      );

      expect(
        buildBattleDecisionPromptForOverlay(continueSession.decisionRequest),
        equals('Le joueur doit continuer un tour forcé'),
      );
    });
  });

  group('BattleOverlayComponent BE10A chronology', () {
    test('renders a voluntary switch before the later enemy attack', () {
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
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final switchIndex =
          lines.indexWhere((line) => line.contains('Joueur switch de'));
      final attackIndex =
          lines.indexWhere((line) => line.contains('Ennemi utilise Tackle'));

      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(attackIndex, greaterThanOrEqualTo(0));
      expect(switchIndex, lessThan(attackIndex));
    });

    test('rejects bucket-only turn results because chronology would be false',
        () {
      const bucketOnlyTurn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(id: 'tackle', name: 'Tackle', power: 40),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 12,
            didHit: true,
          ),
        ],
      );

      expect(
        () => buildBattleTurnLinesForOverlay(bucketOnlyTurn),
        throwsA(isA<StateError>()),
      );
    });

    test(
        'renders end-of-turn residuals before forced replacement markers after a double KO',
        () {
      final session = _session(
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
        isTrainerBattle: true,
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final lines =
          buildBattleTurnLinesForOverlay(afterTurn.state.currentTurn!);

      final residualIndex = lines.indexWhere(
        (line) => line.contains('dégâts résiduels (PSN)'),
      );
      final enemyReplacementIndex = lines.indexWhere(
        (line) => line.contains('Ennemi remplace lead_enemy par bench_enemy'),
      );
      final playerReplacementIndex = lines.indexWhere(
        (line) => line.contains('Joueur doit remplacer lead_player K.O.'),
      );

      expect(residualIndex, greaterThanOrEqualTo(0));
      expect(enemyReplacementIndex, greaterThan(residualIndex));
      expect(playerReplacementIndex, greaterThan(enemyReplacementIndex));
    });
  });
}

```

## 25. État git final utile (mise à jour finale)

### `git status --short --untracked-files=all`

```text
 M packages/map_battle/lib/src/battle_condition_engine.dart
 M packages/map_battle/lib/src/battle_field.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_status.dart
 M packages/map_battle/lib/src/battle_volatile.dart
 M packages/map_battle/test/battle_condition_engine_test.dart
 M packages/map_battle/test/battle_field_test.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
?? reports/phase-g-contract-expansion-report.md
```

### `git diff --stat`

```text
 .../lib/src/battle_condition_engine.dart           | 99 ++++++++++++----------
 packages/map_battle/lib/src/battle_field.dart      | 28 ++++--
 packages/map_battle/lib/src/battle_resolution.dart | 78 ++++++++++++++---
 packages/map_battle/lib/src/battle_session.dart    | 85 ++++++++++++-------
 packages/map_battle/lib/src/battle_status.dart     | 25 ++++--
 packages/map_battle/lib/src/battle_volatile.dart   | 47 ++++++----
 .../test/battle_condition_engine_test.dart         | 76 ++++++++++++++---
 packages/map_battle/test/battle_field_test.dart    | 20 +++++
 .../flame/battle_overlay_component.dart            | 19 +++--
 .../test/battle_overlay_component_test.dart        |  5 +-
 10 files changed, 343 insertions(+), 139 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/phase-g-contract-expansion-report.md
```
