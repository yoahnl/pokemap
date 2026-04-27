# Lot 9-f — Battle BAG super potion support

## Résumé exécutif
Le lot 9-f ajoute `super-potion` au fil BAG battle déjà honnête de `Potion`, sans ouvrir de système générique d’items. Le choix retenu est une mini-factorisation strictement bornée à la famille `Potion + Super Potion` : le moteur battle reçoit un micro-seam typé et non un `itemId` arbitraire, le runtime reste propriétaire du bag réel et du write-back party, et l’overlay réutilise le shell medicine existant.

Concrètement :
- `super-potion` devient sélectionnable dans le BAG battle aux mêmes conditions que `potion`.
- `super-potion` commit un vrai tour, avec vraie timeline et vraie réponse adverse.
- le heal runtime est réel, capé à `maxHp`, et consomme exactement `super-potion`.
- `potion` reste inchangée et prouvée par tests de non-régression.
- aucun registre d’items, aucun catalogue runtime, aucun framework “pour les 2175 objets plus tard” n’a été ouvert.

## Confirmation de scope
Ce lot continue strictement le fil BAG runtime/UI/runtime/battle :
- lot-9a : battle BAG menu UI shell
- lot-9b : capture wiring
- lot-9c : medicine target shell
- lot-9d : Potion real apply
- lot-9e : Potion turn commit
- lot-9f : Super Potion support

Ce lot ne continue pas BDC-01.

Je n’ai pas touché :
- le bridge runtime -> battle des moves
- Bubble / Bubble Beam
- le converter Showdown
- la capture 9-b, hors non-régression
- un système générique d’items battle

## Regard critique sur le prompt
### Points sains
- Le prompt borne explicitement le lot à `super-potion` et refuse un framework générique.
- La question d’architecture `duplication explicite` vs `micro-factorisation bornée` était la bonne question à poser après 9-e.
- L’exigence de critique du prompt lui-même évite de transformer le repo en simple exécuteur de spec potentiellement mauvaise.

### Points discutables ou à corriger
1. **Une duplication pure `Potion` / `Super Potion` aurait été une mauvaise stratégie ici.**
   Après 9-e, le repo avait déjà un pipeline complet “heal item turn commit” avec action battle, timeline, runtime apply et overlay. Dupliquer ce pipeline une seconde fois pour `Super Potion` aurait créé deux branches quasi identiques dans `map_battle`, `map_runtime` et les tests. Le plus petit seam honnête n’était donc plus “objet par objet sans factorisation”, mais une factorisation ultra-bornée à deux objets.

2. **Le prompt parle de “build obligatoire”, mais `packages/map_battle` et `packages/map_runtime` ne sont pas des apps buildables autonomes.**
   Le build complet d’application n’est donc pas applicable à ces packages. La validation honnête ici est :
   - `dart analyze` / `flutter analyze`
   - tests ciblés
   - suites complètes des packages touchés
   - smoke test du host downstream consommateur (`examples/playable_runtime_host`) si pertinent

3. **Le nom du fichier `runtime_battle_potion_apply.dart` devient trompeur après 9-f.**
   Le repo prouve toutefois qu’un renommage maintenant ajouterait un blast radius inutile pour un gain mineur. J’ai donc gardé le fichier historique et documenté explicitement que son seam réel est désormais borné à `Potion + Super Potion`.

4. **Le prompt aurait pu pousser à transporter des `itemId` stringly-typed jusque dans `map_battle`.**
   Le repo montrait qu’un petit enum typé côté battle était plus honnête et plus sûr. J’ai donc retenu un enum borné `BattleBagHpHealItemKind` dans `map_battle`, tout en laissant le runtime continuer à gérer le bag réel par `itemId` concret.

## Audit initial
### Rapports relus
- `/Users/karim/Project/pokemonProject/reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9b-battle-bag-capture-wiring-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9c-battle-bag-medicine-target-shell-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9d-battle-bag-potion-real-apply-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9e-battle-bag-potion-turn-commit-report.md`
- `/Users/karim/Project/pokemonProject/reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`

### Contrats existants identifiés avant modification
- `battle_bag_menu_model.dart` supportait déjà `potion` seulement côté medicine.
- `battle_medicine_target_menu_model.dart` était déjà générique au bon niveau : il transporte `itemId` et cible la lineup battle courante.
- `battle_overlay_component.dart` et `battle_turn_presentation.dart` restaient potion-only dans les prompts, la narration et le callback runtime.
- `runtime_battle_potion_apply.dart` portait déjà le seam runtime réel de `Potion` depuis 9-d/9-e.
- `map_battle` possédait déjà un vrai commit de tour `Potion`, mais sous un seam entièrement spécifique (`BattleActionPotionUse`, `BattleTurnPotionEvent`, etc.).

### Risques identifiés avant implémentation
- ouvrir un faux système générique d’items pour simplement ajouter `super-potion`
- dupliquer le pipeline 9-e et doubler le coût de maintenance
- laisser le runtime et le moteur diverger sur le type d’objet réellement utilisé
- casser `Potion` ou la capture 9-b en refactorant trop large
- mentir via l’overlay avec un feedback local sans vraie timeline moteur

### Canon local de heal
Aucune valeur canonique locale réutilisable pour `super-potion` n’a été trouvée dans le repo. J’ai donc retenu la valeur de fallback demandée par le prompt :
- `potion` = 20 PV
- `super-potion` = 50 PV

## Décision d’architecture
### Choix retenu
**Option B : micro-factorisation strictement bornée à la famille `Potion + Super Potion`.**

### Pourquoi c’est le plus petit seam honnête
- Après 9-e, dupliquer intégralement les seams `Potion` dans battle/runtime/overlay aurait été du bruit, pas de la prudence.
- Le moteur battle reçoit maintenant un petit enum borné `BattleBagHpHealItemKind` et une action `BattleActionBagHpHealItemUse`.
- Ce seam reste explicitement limité à deux objets. Il n’est pas extensible implicitement à `Hyper Potion`, `Antidote`, `Revive`, etc.
- Le runtime continue à posséder la vérité du bag et la consommation réelle des items ; `map_battle` ne lit toujours aucun bag et ne devient pas un moteur d’objets généraliste.

### Ce que j’ai refusé
- un registre d’items battle
- un `itemId` libre au cœur du moteur battle
- un `PlayerBattleChoiceUseItem` générique
- une duplication complète `Potion` / `Super Potion`

## Passes locales nommées (à la place de vrais sub-agents)
L’environnement de cette exécution n’a pas été utilisé avec de vrais sub-agents dédiés à ce lot. J’ai donc fait des passes locales séparées et nommées, sans prétendre le contraire.

- **Pass Audit / Architecture** : `OK`
  J’ai audité les seams potion-only, relu les rapports BAG précédents, et tranché pour une mini-factorisation bornée.
- **Pass Implémentation** : `OK`
  Le moteur battle, le runtime, l’overlay et la présentation supportent maintenant `Potion + Super Potion` sans ouvrir de framework générique.
- **Pass Tests** : `OK`
  J’ai commencé par écrire des tests rouges pour `super-potion`, puis j’ai implémenté jusqu’au vert ciblé et complet.
- **Pass Build / Validation** : `OK`
  Les analyses statiques, tests ciblés, suites complètes et smoke test host sont passés.
- **Pass Critique finale** : `OK`
  Les limites restantes sont documentées ci-dessous, sans masquer les compromis du lot.

## État git initial
Au début du lot, la dirtiness était :

```text
 M generate_project_overview.sh
```

Classification initiale :
- `preexisting_out_of_scope`
  - `/Users/karim/Project/pokemonProject/generate_project_overview.sh`
- `preexisting_in_scope`
  - aucun
- `created_by_this_lot`
  - aucun
- `modified_by_this_lot`
  - aucun au tout début

## Fichiers touchés par ce lot
### Battle
1. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
   - zones modifiées : `BattleBagHpHealItemKind`, `BattleActionBagHpHealItemUse`
   - raison : remplacer l’action potion-only par un seam borné `Potion + Super Potion`
   - impact : le moteur commit désormais deux objets concrets sans devenir générique

2. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart`
   - zones modifiées : whitelist d’actions légales de tour
   - raison : accepter `BattleActionBagHpHealItemUse`
   - impact : le scheduler traite `Potion` et `Super Potion` comme vraies actions de tour

3. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
   - zones modifiées : `bagHpHealItemEvents`, `BattleTurnBagHpHealItemEvent`, `BattleBagHpHealItemEvent`
   - raison : remplacer le bucket potion-only par une trace bornée `Potion + Super Potion`
   - impact : la timeline reste honnête pour les deux objets

4. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
   - zones modifiées : `applyPotionTurn`, `applySuperPotionTurn`, `_applyBagHpHealItemTurn`, `_resolveBagHpHealItemUseAction`, `_requireUsableBagHpHealItemTarget`
   - raison : factoriser le commit de tour et la résolution moteur pour les deux objets
   - impact : `Super Potion` engage un vrai tour comme `Potion`, avec validation de cible honnête

5. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
   - zones modifiées : branche d’ordonnancement des HP-heal bag items, buckets de turn result, timeline
   - raison : raccorder le nouveau seam à la résolution ordonnée du tour
   - impact : l’adversaire répond dans le flow normal après `Super Potion`

6. `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`
   - zones modifiées : tests potion existants + nouveaux tests `Super Potion`
   - raison : prouver le commit de tour, la timeline et la non-régression potion
   - impact : garde-fous moteur explicites

### Runtime
7. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
   - zones modifiées : `RuntimeBattleBagHpHealItemApplyResult`, `tryApplyRuntimeBattlePotionUse`, `tryApplyRuntimeBattleSuperPotionUse`, helpers de write-back/consommation
   - raison : garder le runtime propriétaire du bag réel et du write-back party pour les deux objets
   - impact : `super-potion` soigne réellement et consomme la bonne entrée bag

8. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
   - zones modifiées : `_isSupportedMedicine`
   - raison : rendre `super-potion` sélectionnable dans le BAG battle, sans ouvrir les autres medicines
   - impact : le shell de ciblage medicine existant est réutilisé honnêtement

9. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
   - zones modifiées : narration timeline, prompt medicine, callback `onBagHpHealItemUseRequested`, validation du ciblage medicine
   - raison : rendre l’overlay honnête pour `Super Potion` sans fake feedback local
   - impact : vrai flow de résolution visible côté UI

10. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`
    - zones modifiées : rendu des steps de tour pour les HP-heal items
    - raison : la présentation doit afficher `Super Potion` honnêtement dans la timeline
    - impact : textes `Potion` / `Super Potion` cohérents avec le moteur

11. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
    - zones modifiées : callback runtime du BAG heal item, dispatch `potion` vs `super-potion`, branchement overlay
    - raison : garder `PlayableMapGame` propriétaire de la vérité runtime
    - impact : overlay, `BattleSession` et `GameState` restent synchronisés

### Tests runtime
12. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_bag_menu_model_test.dart`
    - zones modifiées : nouveau test `super-potion selectable`
    - raison : prouver que `super-potion` est disponible sans casser `potion`
    - impact : garde-fou sur le BAG model

13. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
    - zones modifiées : callback overlay, assertions de playerAction, nouveau scénario `Super Potion`
    - raison : prouver le vrai flow overlay -> runtime -> turn commit -> narration
    - impact : garde-fou UI/UX + non-dispatch de faux `PlayerBattleChoice`

14. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
    - zones modifiées : adaptation du seam générique borné + nouveaux tests `Super Potion`
    - raison : prouver le heal réel, le cap `maxHp`, la consommation exacte du bon item
    - impact : garde-fou runtime apply

15. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`
    - zones modifiées : adaptation du seam timeline + nouveau test `Super Potion`
    - raison : prouver la présentation honnête du tour
    - impact : garde-fou narration / timeline

16. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
    - zones modifiées : adaptation des assertions `Potion` + nouveau test `Super Potion`
    - raison : prouver la synchronisation `PlayableMapGame` / overlay / session / gameState
    - impact : garde-fou intégration parent runtime

17. `/Users/karim/Project/pokemonProject/reports/lot-9f-battle-bag-super-potion-support-report.md`
    - zones modifiées : création du rapport complet du lot
    - raison : documenter l’audit, la critique du prompt, les validations et les diffs exhaustifs
    - impact : traçabilité complète du lot 9-f

## Tests créés ou modifiés
### RED écrits avant implémentation
Tests rouges posés avant correction :
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
  - `supported super potion is selectable in a free turn and opens a medicine target action`
- `packages/map_battle/test/battle_session_test.dart`
  - adaptation du seam vers `BattleActionBagHpHealItemUse`
  - `applySuperPotionTurn commits a real turn and records a super potion timeline event`
- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
  - adaptation du seam vers `BattleActionBagHpHealItemUse`
  - `super potion heals a damaged active target by 50 and consumes only super potion`
  - `super potion heal is capped at max hp`
- `packages/map_runtime/test/battle_turn_presentation_test.dart`
  - adaptation de la timeline vers `BattleTurnBagHpHealItemEvent`
  - `renders super potion use as a committed turn step before the enemy response`

### Tests verts finaux couvrant le lot
- BAG model
  - `super-potion` sélectionnable en vrai `BattleTurnChoiceRequest`
  - autre medicine non supportée toujours disabled
  - `Potion` inchangée
- Battle / turn flow
  - `Super Potion` commit un vrai tour
  - l’adversaire répond dans le flow normal
  - la timeline contient un vrai événement `Super Potion`
  - `Potion` continue de commit un vrai tour
- Runtime apply
  - heal réel 50
  - cap `maxHp`
  - quantité 1 supprime l’entrée
  - quantité >1 décrémente de 1
  - `Super Potion` ne consomme pas `Potion`
- Overlay / UX
  - `Super Potion` mène à un vrai flow de résolution
  - prompt/narration reflètent `Super Potion`
  - pas de second choix joueur pour le même tour
- Intégration parent runtime
  - `PlayableMapGame` reste synchronisé
  - pas de divergence entre overlay, session et `GameState`
- Non-régression capture
  - capture lot 9-b inchangée par les suites runtime complètes + tests ciblés

## Commandes de test lancées et résultats exacts
### map_battle
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
  - résultat : `All tests passed!`

### map_runtime ciblé
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_bag_menu_model_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_medicine_target_menu_model_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_potion_apply_runtime_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_turn_presentation_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/wild_battle_end_to_end_flow_test.dart`
  - résultat : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test`
  - résultat : `All tests passed!`

### host downstream
- `cd examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart`
  - résultat : `All tests passed!`

## Commandes d’analyse lancées et résultats exacts
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_action.dart lib/src/battle_queue.dart lib/src/battle_resolution.dart lib/src/battle_session.dart lib/src/battle_session_scheduler.dart test/battle_session_test.dart`
  - résultat : `No issues found!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_potion_apply.dart lib/src/presentation/flame/battle_bag_menu_model.dart lib/src/presentation/flame/battle_overlay_component.dart lib/src/presentation/flame/battle_turn_presentation.dart lib/src/presentation/flame/playable_map_game.dart test/battle_bag_menu_model_test.dart test/battle_overlay_component_test.dart test/battle_potion_apply_runtime_test.dart test/battle_turn_presentation_test.dart test/wild_battle_end_to_end_flow_test.dart`
  - résultat : `No issues found!`

## Build / validation aval
### Build package / app
Aucun build de package autonome n’a été lancé, parce que ce n’est pas applicable ici :
- `packages/map_battle` est une librairie Dart, pas une app buildable seule ;
- `packages/map_runtime` est une librairie Flutter/Flame, pas une app buildable seule.

Validation honnête utilisée à la place :
- analyse statique ciblée
- suites de tests ciblées
- suites complètes des packages touchés
- smoke test du host downstream `examples/playable_runtime_host`

### Host downstream
Le host downstream est pertinent ici, car il consomme directement les seams runtime/overlay touchés. J’ai donc lancé le smoke test :
- `cd examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart`
  - résultat : `All tests passed!`

## État git final
```text
 M generate_project_overview.sh
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_queue.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_bag_menu_model_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_potion_apply_runtime_test.dart
 M packages/map_runtime/test/battle_turn_presentation_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/lot-9f-battle-bag-super-potion-support-report.md
```

Classification finale :
- `preexisting_out_of_scope`
  - `/Users/karim/Project/pokemonProject/generate_project_overview.sh`
- `modified_by_this_lot`
  - les 16 fichiers listés dans la section “Fichiers touchés par ce lot”
- `created_by_this_lot`
  - `/Users/karim/Project/pokemonProject/reports/lot-9f-battle-bag-super-potion-support-report.md`
- `deleted_by_this_lot`
  - aucun

## Limites explicitement conservées
- aucun système générique d’items battle
- aucun registre d’items
- aucun catalogue runtime d’items
- aucune medicine autre que `potion` et `super-potion`
- aucun `Antidote`, `Hyper Potion`, `Revive`, `Full Restore`, `X Attack`
- aucun held item
- aucune modification du bridge runtime -> battle des moves
- aucune modification Bubble / Bubble Beam / BDC-01
- aucune modification du flow capture 9-b, hors non-régression

## Auto-critique finale
### Risques restants
1. **Le nom du fichier `runtime_battle_potion_apply.dart` est désormais historiquement faux.**
   Le code reste correct et explicitement commenté, mais le nom peut surprendre un futur lecteur.

2. **Le runtime reste propriétaire de la disponibilité bag et de la consommation réelle.**
   C’est volontaire et sain dans cette architecture, mais cela signifie que `map_battle` ne protège pas seul contre un appel runtime illégal. Les wrappers runtime et les tests restent donc importants.

3. **La factorisation reste volontairement incomplète.**
   C’est une force pour 9-f, mais aussi une limite : ajouter `Hyper Potion` ou `Antidote` nécessitera encore un lot explicite, pas juste une entrée de plus dans une table.

4. **Le heal de réserve reste surtout visible par narration et HUD/état, pas par une animation item dédiée.**
   C’est cohérent avec le lot, mais un futur lot pourrait vouloir enrichir la présentation pour les cibles hors actif sans changer le contrat moteur.

### Tests éventuellement encore manquants
- un test dédié de refus explicite `super-potion` quand la request n’autorise pas le BAG, analogue à certains tests potion déjà présents
- un test de non-régression ultra-direct sur la capture après un refactor de callback overlay, même si la suite complète runtime couvre déjà ce risque indirectement

### Choix discutables assumés
- **garder le fichier `runtime_battle_potion_apply.dart`** plutôt que le renommer immédiatement : moins de churn, mais nom historique imparfait
- **introduire un enum battle borné** plutôt que garder des `itemId` strings jusque dans `map_battle` : j’assume ce choix, car il protège mieux la frontière anti-framework

### Pourquoi le lot reste borné
- côté battle, le seam est borné par `BattleBagHpHealItemKind` à exactement deux cas
- côté runtime, il n’existe toujours que deux façades publiques : `tryApplyRuntimeBattlePotionUse` et `tryApplyRuntimeBattleSuperPotionUse`
- côté BAG model, seules `potion` et `super-potion` deviennent supportées
- aucune structure “ouverte” type registre, catalogue ou `item effect kind` extensible n’a été introduite

## Prochaines étapes proposées, sans implémentation
- lot explicite pour `Hyper Potion` uniquement si le besoin produit existe vraiment
- lot séparé pour une autre famille d’objets battle, par exemple status-heal, avec une nouvelle décision d’architecture dédiée
- éventuel renommage/documentation plus claire de `runtime_battle_potion_apply.dart` si plusieurs lots bornés de BAG heal items s’accumulent

## Diff exhaustif de tous les fichiers touchés par le lot
Le diff ci-dessous couvre **tous les fichiers de code modifiés** par le lot 9-f. Le fichier préexistant hors scope `generate_project_overview.sh` n’est pas inclus, car il n’a pas été touché par ce lot. Le présent report n’est pas ré-embarqué dans son propre diff pour éviter une récursion documentaire infinie ; son contenu complet est précisément le document que tu lis.

```diff
diff --git a/packages/map_battle/lib/src/battle_action.dart b/packages/map_battle/lib/src/battle_action.dart
index a58ceeb6..d12cf536 100644
--- a/packages/map_battle/lib/src/battle_action.dart
+++ b/packages/map_battle/lib/src/battle_action.dart
@@ -120,23 +120,52 @@ class BattleActionRun extends BattleAction {
   const BattleActionRun();
 }
 
-/// Utiliser une Potion sur un membre du lineup joueur courant.
+/// Famille ultra-bornée d'objets de soin HP supportés en BAG battle.
 ///
-/// Lot 9-e ouvre ici un seam volontairement ultra-borné :
-/// - aucune taxonomie générique d'objets battle ;
-/// - aucune lecture de bag côté moteur ;
-/// - aucune famille "item use" extensible pour 20 objets ;
-/// - uniquement la forme minimale nécessaire pour faire de `Potion`
-///   une vraie action de tour committée et visible dans la timeline.
+/// Lot 9-f factorise seulement ce qui devenait absurde à dupliquer :
+/// - `potion`
+/// - `super-potion`
 ///
-/// Le runtime reste responsable de deux vérités hors moteur :
-/// - vérifier qu'une Potion existe vraiment dans le `GameState.bag` ;
-/// - décrémenter cette entrée après un commit de tour réussi.
-class BattleActionPotionUse extends BattleAction {
-  const BattleActionPotionUse({
+/// Garde-fous de frontière :
+/// - ce n'est pas un catalogue runtime d'objets ;
+/// - ce n'est pas une taxonomie générale de medicines ;
+/// - aucune autre entrée (`antidote`, `hyper-potion`, `revive`, etc.)
+///   n'est implicite ou "préparée".
+enum BattleBagHpHealItemKind {
+  potion,
+  superPotion;
+
+  String get itemId => switch (this) {
+        BattleBagHpHealItemKind.potion => 'potion',
+        BattleBagHpHealItemKind.superPotion => 'super-potion',
+      };
+
+  String get label => switch (this) {
+        BattleBagHpHealItemKind.potion => 'Potion',
+        BattleBagHpHealItemKind.superPotion => 'Super Potion',
+      };
+}
+
+/// Utiliser un objet BAG de soin HP plat sur un membre du lineup joueur.
+///
+/// Cette action reste volontairement très étroite :
+/// - elle couvre seulement `Potion` + `Super Potion` ;
+/// - elle ne lit jamais le bag ;
+/// - elle n'ouvre pas un système générique d'items battle ;
+/// - elle existe uniquement pour rendre ces deux objets honnêtes comme vraies
+///   actions de tour committées et visibles dans la timeline.
+class BattleActionBagHpHealItemUse extends BattleAction {
+  const BattleActionBagHpHealItemUse({
+    required this.itemKind,
     required this.targetLineupIndex,
     required this.healAmount,
-  }) : assert(healAmount > 0, 'Potion healAmount must stay strictly positive.');
+  }) : assert(healAmount > 0, 'HP-heal item healAmount must stay positive.');
+
+  /// L'objet précis réellement utilisé.
+  ///
+  /// Le `kind` reste borné à deux cas, ce qui évite de transporter un
+  /// `itemId` stringly-typed arbitraire dans le moteur.
+  final BattleBagHpHealItemKind itemKind;
 
   /// Lineup cible côté joueur.
   ///
@@ -146,8 +175,8 @@ class BattleActionPotionUse extends BattleAction {
 
   /// Quantité de soin plate réellement portée par cette action.
   ///
-  /// Lot 9-e reste borné à la vraie `Potion` locale ; ce champ n'ouvre pas
-  /// un catalogue d'effets d'items.
+  /// Le runtime décide encore si l'objet est disponible dans le bag ;
+  /// le moteur ne consomme ici que l'effet déjà autorisé.
   final int healAmount;
 }
 
diff --git a/packages/map_battle/lib/src/battle_queue.dart b/packages/map_battle/lib/src/battle_queue.dart
index 69d1c63b..27f91ebc 100644
--- a/packages/map_battle/lib/src/battle_queue.dart
+++ b/packages/map_battle/lib/src/battle_queue.dart
@@ -13,7 +13,8 @@ import 'battle_topology.dart';
 ///
 /// Son rôle est uniquement de devenir la vraie source de vérité du scheduling
 /// interne du tour :
-/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`, `Potion`) ;
+/// - des actions déjà légales (`Fight`, `Switch`, `Recharge`, `Potion`,
+///   `Super Potion`) ;
 /// - de la fin de tour ;
 /// - des checks post-résolution ;
 /// - des remplacements déjà honnêtement supportés.
@@ -86,7 +87,7 @@ sealed class BattleQueueStep {
 ///   pseudo commande universelle.
 bool isBattleQueueManagedAction(BattleAction action) {
   return action is BattleActionFight ||
-      action is BattleActionPotionUse ||
+      action is BattleActionBagHpHealItemUse ||
       action is BattleActionRecharge ||
       action is BattleActionSwitch;
 }
@@ -108,7 +109,7 @@ final class BattleQueueActionStep extends BattleQueueStep {
       throw ArgumentError.value(
         action,
         'action',
-        'BattleQueueActionStep n’accepte que Fight/Potion/Switch/Recharge.',
+        'BattleQueueActionStep n’accepte que Fight/HP-heal-item/Switch/Recharge.',
       );
     }
     return BattleQueueActionStep._(
diff --git a/packages/map_battle/lib/src/battle_resolution.dart b/packages/map_battle/lib/src/battle_resolution.dart
index c173cf7a..22109d0a 100644
--- a/packages/map_battle/lib/src/battle_resolution.dart
+++ b/packages/map_battle/lib/src/battle_resolution.dart
@@ -24,7 +24,7 @@ class BattleTurnResult {
   /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
   /// [stealthRockEvents] - Les événements Stealth Rock visibles du tour.
   /// [spikesEvents] - Les événements Spikes visibles du tour.
-  /// [potionEvents] - Les usages de Potion visibles du tour.
+  /// [bagHpHealItemEvents] - Les usages visibles de Potion / Super Potion.
   /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
   const BattleTurnResult({
     required this.playerAction,
@@ -35,7 +35,7 @@ class BattleTurnResult {
     this.fieldEvents = const <BattleFieldEvent>[],
     this.stealthRockEvents = const <BattleStealthRockEvent>[],
     this.spikesEvents = const <BattleSpikesEvent>[],
-    this.potionEvents = const <BattlePotionEvent>[],
+    this.bagHpHealItemEvents = const <BattleBagHpHealItemEvent>[],
     this.switchEvents = const <BattleSwitchEvent>[],
     this.timeline = const <BattleTurnEvent>[],
   });
@@ -98,14 +98,15 @@ class BattleTurnResult {
   /// - ce lot porte donc son propre contrat dédié, vivant et testable.
   final List<BattleSpikesEvent> spikesEvents;
 
-  /// Les usages de Potion visibles pendant ce tour.
+  /// Les usages visibles d'objets BAG à soin HP plat pendant ce tour.
   ///
-  /// Lot 9-e choisit ici un contrat explicitement non générique :
-  /// - ce bucket ne devient pas "itemsEvents" ;
-  /// - il ne couvre ni Antidote, ni Super Potion, ni objets tenus ;
-  /// - il sert uniquement à rendre l'action `Potion` observable quand elle
-  ///   devient une vraie action de tour committée.
-  final List<BattlePotionEvent> potionEvents;
+  /// Lot 9-f choisit une mini-factorisation bornée plutôt qu'une duplication
+  /// intégrale du pipeline 9-e :
+  /// - ce bucket ne devient pas `itemEvents` ;
+  /// - il ne couvre que `Potion` + `Super Potion` ;
+  /// - toute autre medicine reste hors scope tant qu'un lot explicite ne la
+  ///   branche pas réellement.
+  final List<BattleBagHpHealItemEvent> bagHpHealItemEvents;
 
   /// Les événements de switch / remplacement visibles pendant ce tour.
   ///
@@ -183,10 +184,10 @@ final class BattleTurnSpikesEvent extends BattleTurnEvent {
   final BattleSpikesEvent event;
 }
 
-final class BattleTurnPotionEvent extends BattleTurnEvent {
-  const BattleTurnPotionEvent(this.event);
+final class BattleTurnBagHpHealItemEvent extends BattleTurnEvent {
+  const BattleTurnBagHpHealItemEvent(this.event);
 
-  final BattlePotionEvent event;
+  final BattleBagHpHealItemEvent event;
 }
 
 final class BattleTurnSwitchEvent extends BattleTurnEvent {
@@ -195,15 +196,17 @@ final class BattleTurnSwitchEvent extends BattleTurnEvent {
   final BattleSwitchEvent event;
 }
 
-/// Trace visible d'un vrai usage de `Potion` pendant un tour.
+/// Trace visible d'un vrai usage de `Potion` ou `Super Potion`.
 ///
-/// Frontière volontairement serrée :
-/// - on ne transporte pas un "itemId" arbitraire ;
-/// - on ne généralise pas vers un journal d'objets battle ;
-/// - on porte seulement les données nécessaires pour raconter honnêtement
-///   l'usage de Potion et la variation réelle de PV.
-final class BattlePotionEvent {
-  const BattlePotionEvent({
+/// La factorisation reste honnête parce qu'elle est bornée par
+/// [BattleBagHpHealItemKind] :
+/// - pas d'`itemId` arbitraire ;
+/// - pas de registre d'objets ;
+/// - seulement les données nécessaires pour raconter les deux objets de soin
+///   HP plats réellement supportés à ce stade.
+final class BattleBagHpHealItemEvent {
+  const BattleBagHpHealItemEvent({
+    required this.itemKind,
     required this.side,
     required this.targetLineupIndex,
     required this.targetSpeciesId,
@@ -211,6 +214,7 @@ final class BattlePotionEvent {
     required this.hpAfter,
   });
 
+  final BattleBagHpHealItemKind itemKind;
   final BattleSideId side;
   final int targetLineupIndex;
   final String targetSpeciesId;
diff --git a/packages/map_battle/lib/src/battle_session.dart b/packages/map_battle/lib/src/battle_session.dart
index ad25fbe9..719f265b 100644
--- a/packages/map_battle/lib/src/battle_session.dart
+++ b/packages/map_battle/lib/src/battle_session.dart
@@ -270,24 +270,56 @@ class BattleSession {
 
   /// Commit une vraie action de tour `Potion`.
   ///
-  /// Lot 9-e refuse ici deux faux raccourcis :
-  /// - continuer l'ancien "patch runtime local" 9-d sans vrai `currentTurn` ;
-  /// - ouvrir un framework générique d'items battle.
-  ///
-  /// Ce seam reste donc volontairement étroit :
-  /// - une seule action publique, spécifique à `Potion` ;
-  /// - ciblage par `lineupIndex` battle déjà stable ;
-  /// - aucun bag, aucune consommation d'objet, aucun catalogue d'items ici ;
-  /// - la consommation réelle du bag reste côté runtime une fois le tour
-  ///   effectivement committé par le moteur.
+  /// Lot 9-f conserve cette façade explicite pour éviter de vendre une API
+  /// générique d'objets : l'implémentation factorise en interne avec
+  /// `Super Potion`, mais l'appelant reste bien sur un objet concret.
   BattleSession applyPotionTurn({
     required int targetLineupIndex,
     required int healAmount,
+  }) {
+    return _applyBagHpHealItemTurn(
+      itemKind: BattleBagHpHealItemKind.potion,
+      targetLineupIndex: targetLineupIndex,
+      healAmount: healAmount,
+    );
+  }
+
+  /// Commit une vraie action de tour `Super Potion`.
+  ///
+  /// Frontière volontaire :
+  /// - on n'étend pas cette API à toutes les medicines ;
+  /// - on ajoute seulement le deuxième objet explicitement demandé par 9-f ;
+  /// - l'effet reste committé via le même scheduler honnête que `Potion`.
+  BattleSession applySuperPotionTurn({
+    required int targetLineupIndex,
+    required int healAmount,
+  }) {
+    return _applyBagHpHealItemTurn(
+      itemKind: BattleBagHpHealItemKind.superPotion,
+      targetLineupIndex: targetLineupIndex,
+      healAmount: healAmount,
+    );
+  }
+
+  /// Commit une vraie action de tour pour la famille ultra-bornée
+  /// `Potion` + `Super Potion`.
+  ///
+  /// Ce helper interne factorise seulement ce qui était devenu duplication :
+  /// - même validation de requête ;
+  /// - même ciblage par `lineupIndex` ;
+  /// - même scheduler de tour ;
+  /// - même narration battle.
+  ///
+  /// Il ne doit pas dériver vers un système d'items générique.
+  BattleSession _applyBagHpHealItemTurn({
+    required BattleBagHpHealItemKind itemKind,
+    required int targetLineupIndex,
+    required int healAmount,
   }) {
     final request = decisionRequest;
     if (request is! BattleTurnChoiceRequest) {
       throw StateError(
-        'Potion ne peut être engagée que pendant un vrai BattleTurnChoiceRequest '
+        '${itemKind.label} ne peut être engagée que pendant un vrai BattleTurnChoiceRequest '
         '(request=${request.runtimeType}).',
       );
     }
@@ -295,17 +327,18 @@ class BattleSession {
       throw ArgumentError.value(
         healAmount,
         'healAmount',
-        'Potion healAmount must stay strictly positive.',
+        '${itemKind.label} healAmount must stay strictly positive.',
       );
     }
 
-    _requireUsablePotionTarget(
+    _requireUsableBagHpHealItemTarget(
       side: state.playerSide,
       targetLineupIndex: targetLineupIndex,
     );
 
     return _applyCommittedPlayerAction(
-      playerAction: BattleActionPotionUse(
+      playerAction: BattleActionBagHpHealItemUse(
+        itemKind: itemKind,
         targetLineupIndex: targetLineupIndex,
         healAmount: healAmount,
       ),
@@ -765,36 +798,38 @@ class BattleSession {
     );
   }
 
-  _ResolvedPotionUseAction _resolvePotionUseAction({
+  _ResolvedBagHpHealItemUseAction _resolveBagHpHealItemUseAction({
+    required BattleBagHpHealItemKind itemKind,
     required BattleSideState side,
     required int targetLineupIndex,
     required int healAmount,
   }) {
     if (side.id != BattleSideId.player) {
       throw StateError(
-        'BattleActionPotionUse reste limité au côté joueur dans le lot 9-e.',
+        'BattleActionBagHpHealItemUse reste limité au côté joueur dans le lot 9-f.',
       );
     }
     if (healAmount <= 0) {
       throw ArgumentError.value(
         healAmount,
         'healAmount',
-        'Potion healAmount must stay strictly positive.',
+        '${itemKind.label} healAmount must stay strictly positive.',
       );
     }
 
-    final targetCombatant = _requireUsablePotionTarget(
+    final targetCombatant = _requireUsableBagHpHealItemTarget(
       side: side,
       targetLineupIndex: targetLineupIndex,
     );
     final healedCombatant = targetCombatant.withHeal(healAmount);
 
-    return _ResolvedPotionUseAction(
+    return _ResolvedBagHpHealItemUseAction(
       side: _replacePlayerCombatantByLineupIndex(
         side: side,
         updatedCombatant: healedCombatant,
       ),
-      event: BattlePotionEvent(
+      event: BattleBagHpHealItemEvent(
+        itemKind: itemKind,
         side: side.id,
         targetLineupIndex: healedCombatant.lineupIndex,
         targetSpeciesId: healedCombatant.speciesId,
@@ -1769,14 +1804,14 @@ class _ResolvedSwitchAction {
   final BattleSwitchEvent event;
 }
 
-class _ResolvedPotionUseAction {
-  const _ResolvedPotionUseAction({
+class _ResolvedBagHpHealItemUseAction {
+  const _ResolvedBagHpHealItemUseAction({
     required this.side,
     required this.event,
   });
 
   final BattleSideState side;
-  final BattlePotionEvent event;
+  final BattleBagHpHealItemEvent event;
 }
 
 class _ResolvedMoveExecution {
@@ -1895,7 +1930,7 @@ BattleSideState _replacePlayerCombatantByLineupIndex({
   return side.withReserve(updatedReserve);
 }
 
-BattleCombatant _requireUsablePotionTarget({
+BattleCombatant _requireUsableBagHpHealItemTarget({
   required BattleSideState side,
   required int targetLineupIndex,
 }) {
@@ -1905,19 +1940,19 @@ BattleCombatant _requireUsablePotionTarget({
   );
   if (combatant == null) {
     throw StateError(
-      'Potion vise un lineupIndex joueur introuvable dans la session courante '
+      'Un objet BAG de soin HP vise un lineupIndex joueur introuvable dans la session courante '
       '(lineupIndex=$targetLineupIndex).',
     );
   }
   if (combatant.isFainted) {
     throw StateError(
-      'Potion ne peut pas cibler un combattant joueur K.O. '
+      'Un objet BAG de soin HP ne peut pas cibler un combattant joueur K.O. '
       '(lineupIndex=$targetLineupIndex).',
     );
   }
   if (combatant.currentHp >= combatant.maxHp) {
     throw StateError(
-      'Potion ne peut pas cibler un combattant déjà full HP '
+      'Un objet BAG de soin HP ne peut pas cibler un combattant déjà full HP '
       '(lineupIndex=$targetLineupIndex).',
     );
   }
diff --git a/packages/map_battle/lib/src/battle_session_scheduler.dart b/packages/map_battle/lib/src/battle_session_scheduler.dart
index 6c18ca3b..baa7f1b1 100644
--- a/packages/map_battle/lib/src/battle_session_scheduler.dart
+++ b/packages/map_battle/lib/src/battle_session_scheduler.dart
@@ -269,7 +269,8 @@ BattleTurnResult _buildTurnResultFromContext({
     stealthRockEvents:
         List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
     spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
-    potionEvents: List<BattlePotionEvent>.unmodifiable(turn.potionEvents),
+    bagHpHealItemEvents:
+        List<BattleBagHpHealItemEvent>.unmodifiable(turn.bagHpHealItemEvents),
     switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
     timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
   );
@@ -446,24 +447,26 @@ void _executeActionQueueStep({
   }
 
   if (step.action
-      case BattleActionPotionUse(
+      case BattleActionBagHpHealItemUse(
+        :final itemKind,
         :final targetLineupIndex,
         :final healAmount,
       )) {
     if (step.side != BattleSideId.player) {
       throw StateError(
-        'BattleActionPotionUse reste player-only dans le lot 9-e.',
+        'BattleActionBagHpHealItemUse reste player-only dans le lot 9-f.',
       );
     }
 
-    final resolution = session._resolvePotionUseAction(
+    final resolution = session._resolveBagHpHealItemUseAction(
+      itemKind: itemKind,
       side: actingSide,
       targetLineupIndex: targetLineupIndex,
       healAmount: healAmount,
     );
     turn.updateSide(step.side, resolution.side);
-    turn.potionEvents.add(resolution.event);
-    turn.timeline.add(BattleTurnPotionEvent(resolution.event));
+    turn.bagHpHealItemEvents.add(resolution.event);
+    turn.timeline.add(BattleTurnBagHpHealItemEvent(resolution.event));
     return;
   }
 
@@ -812,11 +815,11 @@ int _priorityForResolvedAction(BattleAction action) {
     // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
     //   des priorités de switch.
     //
-    // Lot 9-e ajoute un seul cas de plus :
-    // - `Potion` doit devenir une vraie action de tour ;
-    // - elle résout avant les moves actuellement supportés ;
+    // Lots 9-e / 9-f ajoutent un seul micro-slice d'objets :
+    // - `Potion` et `Super Potion` deviennent de vraies actions de tour ;
+    // - elles résolvent avant les moves actuellement supportés ;
     // - on refuse pourtant d'ouvrir une échelle générique de priorités items.
-    BattleActionPotionUse() => 7,
+    BattleActionBagHpHealItemUse() => 7,
     BattleActionSwitch() => 6,
     BattleActionFight(:final move) => move.priority,
     BattleActionRecharge() => 0,
@@ -850,7 +853,7 @@ final class _PendingTurnContinuation {
     required this.fieldEvents,
     required this.stealthRockEvents,
     required this.spikesEvents,
-    required this.potionEvents,
+    required this.bagHpHealItemEvents,
     required this.switchEvents,
     required this.timeline,
   });
@@ -878,7 +881,9 @@ final class _PendingTurnContinuation {
       stealthRockEvents:
           List<BattleStealthRockEvent>.unmodifiable(turn.stealthRockEvents),
       spikesEvents: List<BattleSpikesEvent>.unmodifiable(turn.spikesEvents),
-      potionEvents: List<BattlePotionEvent>.unmodifiable(turn.potionEvents),
+      bagHpHealItemEvents: List<BattleBagHpHealItemEvent>.unmodifiable(
+        turn.bagHpHealItemEvents,
+      ),
       switchEvents: List<BattleSwitchEvent>.unmodifiable(turn.switchEvents),
       timeline: List<BattleTurnEvent>.unmodifiable(turn.timeline),
     );
@@ -898,7 +903,7 @@ final class _PendingTurnContinuation {
   final List<BattleFieldEvent> fieldEvents;
   final List<BattleStealthRockEvent> stealthRockEvents;
   final List<BattleSpikesEvent> spikesEvents;
-  final List<BattlePotionEvent> potionEvents;
+  final List<BattleBagHpHealItemEvent> bagHpHealItemEvents;
   final List<BattleSwitchEvent> switchEvents;
   final List<BattleTurnEvent> timeline;
 }
@@ -936,7 +941,7 @@ final class _QueuedTurnContext {
       ..fieldEvents.addAll(pending.fieldEvents)
       ..stealthRockEvents.addAll(pending.stealthRockEvents)
       ..spikesEvents.addAll(pending.spikesEvents)
-      ..potionEvents.addAll(pending.potionEvents)
+      ..bagHpHealItemEvents.addAll(pending.bagHpHealItemEvents)
       ..switchEvents.addAll(pending.switchEvents)
       ..timeline.addAll(pending.timeline);
   }
@@ -957,7 +962,8 @@ final class _QueuedTurnContext {
   final List<BattleStealthRockEvent> stealthRockEvents =
       <BattleStealthRockEvent>[];
   final List<BattleSpikesEvent> spikesEvents = <BattleSpikesEvent>[];
-  final List<BattlePotionEvent> potionEvents = <BattlePotionEvent>[];
+  final List<BattleBagHpHealItemEvent> bagHpHealItemEvents =
+      <BattleBagHpHealItemEvent>[];
   final List<BattleSwitchEvent> switchEvents = <BattleSwitchEvent>[];
   final List<BattleTurnEvent> timeline = <BattleTurnEvent>[];
 
diff --git a/packages/map_battle/test/battle_session_test.dart b/packages/map_battle/test/battle_session_test.dart
index 22ff0c75..04e1017e 100644
--- a/packages/map_battle/test/battle_session_test.dart
+++ b/packages/map_battle/test/battle_session_test.dart
@@ -991,20 +991,26 @@ void main() {
       expect(updatedSession.state.player.currentHp, equals(32));
       expect(
         updatedSession.state.currentTurn!.playerAction,
-        isA<BattleActionPotionUse>(),
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.potion),
+        ),
       );
       expect(
         updatedSession.state.currentTurn!.enemyAction,
         isA<BattleActionFight>(),
       );
-      expect(updatedSession.state.currentTurn!.potionEvents, hasLength(1));
       expect(
-        updatedSession.state.currentTurn!.potionEvents.single.healedAmount,
+          updatedSession.state.currentTurn!.bagHpHealItemEvents, hasLength(1));
+      expect(
+        updatedSession
+            .state.currentTurn!.bagHpHealItemEvents.single.healedAmount,
         equals(20),
       );
       expect(
         updatedSession.state.currentTurn!.timeline.first,
-        isA<BattleTurnPotionEvent>(),
+        isA<BattleTurnBagHpHealItemEvent>(),
       );
       expect(
         updatedSession.state.currentTurn!.timeline.last,
@@ -1078,5 +1084,72 @@ void main() {
       expect(session.state.player.currentHp, equals(40));
       expect(session.state.playerReserve.single.currentHp, equals(0));
     });
+
+    test(
+        'applySuperPotionTurn commits a real turn and records a super potion timeline event',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 80,
+            currentHp: 12,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
+            ],
+          ),
+          enemyPokemon: const BattleCombatantData(
+            speciesId: 'sparkitten',
+            level: 10,
+            maxHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(
+                id: 'wait',
+                name: 'Wait',
+                power: 0,
+                category: BattleMoveCategory.status,
+                target: BattleMoveTarget.self,
+                accuracy: BattleMoveAccuracy.alwaysHits(),
+              ),
+            ],
+          ),
+          isTrainerBattle: true,
+          trainerId: 'trainer_1',
+        ),
+      );
+
+      final updatedSession = session.applySuperPotionTurn(
+        targetLineupIndex: 0,
+        healAmount: 50,
+      );
+
+      expect(updatedSession.state.currentTurn, isNotNull);
+      expect(updatedSession.state.player.currentHp, equals(62));
+      expect(
+        updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.superPotion),
+        ),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents,
+        hasLength(1),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.superPotion),
+      );
+      expect(
+        updatedSession.state.currentTurn!.timeline.first,
+        isA<BattleTurnBagHpHealItemEvent>(),
+      );
+    });
   });
 }
diff --git a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart b/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
index e1709637..f8084111 100644
--- a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
+++ b/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
@@ -3,14 +3,15 @@ import 'package:map_core/map_core.dart';
 
 import 'runtime_battle_outcome_apply.dart';
 
-const _runtimeBattlePotionItemId = 'potion';
-const _runtimeBattlePotionCategoryId = 'medicine';
+const _runtimeBattleMedicineCategoryId = 'medicine';
 const _runtimeBattlePotionHealAmount = 20;
+const _runtimeBattleSuperPotionHealAmount = 50;
 
-class RuntimeBattlePotionApplyResult {
-  const RuntimeBattlePotionApplyResult({
+class RuntimeBattleBagHpHealItemApplyResult {
+  const RuntimeBattleBagHpHealItemApplyResult({
     required this.updatedSession,
     required this.updatedGameState,
+    required this.itemKind,
     required this.targetSpeciesId,
     required this.targetLineupIndex,
     required this.healedAmount,
@@ -18,21 +19,58 @@ class RuntimeBattlePotionApplyResult {
 
   final BattleSession updatedSession;
   final GameState updatedGameState;
+  final BattleBagHpHealItemKind itemKind;
   final String targetSpeciesId;
   final int targetLineupIndex;
   final int healedAmount;
 }
 
-// Lot 9-e absorbe l'ancien apply local 9-d dans un vrai commit de tour :
-// - `map_battle` résout maintenant un vrai `currentTurn` spécifique à Potion ;
-// - ce helper reste pourtant runtime-only pour le bag et le write-back party ;
-// - on n'ouvre toujours aucun système générique d'items battle ;
-// - on ne fabrique jamais de `PlayerBattleChoiceUseItem`.
-RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
+/// Lot 9-f garde le fichier historique pour minimiser le blast radius, mais le
+/// seam réel n'est plus "Potion seulement" :
+/// - on supporte exactement `Potion` + `Super Potion` ;
+/// - on refuse tout autre item ;
+/// - le moteur battle commit le vrai tour ;
+/// - le runtime reste propriétaire du bag réel et du write-back party.
+RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattlePotionUse({
   required BattleSession session,
   required GameState gameState,
   required RuntimeActiveBattleContext context,
   required int targetLineupIndex,
+}) {
+  return _tryApplyRuntimeBattleBagHpHealItemUse(
+    session: session,
+    gameState: gameState,
+    context: context,
+    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.potion),
+    targetLineupIndex: targetLineupIndex,
+  );
+}
+
+/// Support explicite ajouté par le lot 9-f.
+///
+/// On garde une façade par objet pour ne pas vendre une API runtime "tous
+/// items", même si l'implémentation partage le cœur avec `Potion`.
+RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleSuperPotionUse({
+  required BattleSession session,
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required int targetLineupIndex,
+}) {
+  return _tryApplyRuntimeBattleBagHpHealItemUse(
+    session: session,
+    gameState: gameState,
+    context: context,
+    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.superPotion),
+    targetLineupIndex: targetLineupIndex,
+  );
+}
+
+RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
+  required BattleSession session,
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+  required int targetLineupIndex,
 }) {
   if (session.decisionRequest is! BattleTurnChoiceRequest) {
     return null;
@@ -48,30 +86,40 @@ RuntimeBattlePotionApplyResult? tryApplyRuntimeBattlePotionUse({
     return null;
   }
 
-  if (!_hasPotionAvailable(gameState.bag)) {
+  if (!_hasBagHpHealItemAvailable(
+    bag: gameState.bag,
+    itemSpec: itemSpec,
+  )) {
     return null;
   }
 
-  final healedCombatant =
-      targetCombatant.withHeal(_runtimeBattlePotionHealAmount);
+  final healedCombatant = targetCombatant.withHeal(itemSpec.healAmount);
   final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
   if (healedAmount <= 0) {
     return null;
   }
 
-  final updatedSession = session.applyPotionTurn(
-    targetLineupIndex: targetLineupIndex,
-    healAmount: _runtimeBattlePotionHealAmount,
-  );
-  final updatedGameState = _applyCommittedPotionTurnToRuntimeState(
+  final updatedSession = switch (itemSpec.kind) {
+    BattleBagHpHealItemKind.potion => session.applyPotionTurn(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: itemSpec.healAmount,
+      ),
+    BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: itemSpec.healAmount,
+      ),
+  };
+  final updatedGameState = _applyCommittedBagHpHealItemTurnToRuntimeState(
     gameState: gameState,
     context: context,
     updatedSession: updatedSession,
+    itemSpec: itemSpec,
   );
 
-  return RuntimeBattlePotionApplyResult(
+  return RuntimeBattleBagHpHealItemApplyResult(
     updatedSession: updatedSession,
     updatedGameState: updatedGameState,
+    itemKind: itemSpec.kind,
     targetSpeciesId: healedCombatant.speciesId,
     targetLineupIndex: healedCombatant.lineupIndex,
     healedAmount: healedAmount,
@@ -94,14 +142,15 @@ BattleCombatant? _findPlayerCombatantByLineupIndex({
   return null;
 }
 
-// Lot 9-e écrit désormais la vraie vérité runtime après un tour committé :
-// - toute la lineup battle joueur engagée est réécrite sur la vraie party ;
-// - la Potion est consommée exactement une fois après un commit battle réussi ;
-// - aucun faux "state overlay only" ne survit.
-GameState _applyCommittedPotionTurnToRuntimeState({
+// Lot 9-f reste runtime-owner pour la vérité hors moteur :
+// - write-back réel de toute la lineup engagée ;
+// - consommation réelle du bon item de bag ;
+// - aucune divergence overlay-only.
+GameState _applyCommittedBagHpHealItemTurnToRuntimeState({
   required GameState gameState,
   required RuntimeActiveBattleContext context,
   required BattleSession updatedSession,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
 }) {
   final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
     gameState: gameState,
@@ -109,28 +158,37 @@ GameState _applyCommittedPotionTurnToRuntimeState({
     battleState: updatedSession.state,
   );
   return withCommittedHp.copyWith(
-    bag: _consumeOnePotionOrThrow(withCommittedHp.bag),
+    bag: _consumeOneBagHpHealItemOrThrow(
+      bag: withCommittedHp.bag,
+      itemSpec: itemSpec,
+    ),
   );
 }
 
-bool _hasPotionAvailable(Bag bag) {
+bool _hasBagHpHealItemAvailable({
+  required Bag bag,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+}) {
   for (final entry in bag.normalized().entries) {
-    if (entry.itemId == _runtimeBattlePotionItemId &&
-        entry.categoryId == _runtimeBattlePotionCategoryId) {
+    if (entry.itemId == itemSpec.itemId &&
+        entry.categoryId == _runtimeBattleMedicineCategoryId) {
       return true;
     }
   }
   return false;
 }
 
-Bag _consumeOnePotionOrThrow(Bag bag) {
+Bag _consumeOneBagHpHealItemOrThrow({
+  required Bag bag,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+}) {
   final nextEntries = <BagEntry>[];
   var consumed = false;
 
   for (final entry in bag.normalized().entries) {
-    final isPotion = entry.itemId == _runtimeBattlePotionItemId &&
-        entry.categoryId == _runtimeBattlePotionCategoryId;
-    if (!isPotion) {
+    final isRequestedItem = entry.itemId == itemSpec.itemId &&
+        entry.categoryId == _runtimeBattleMedicineCategoryId;
+    if (!isRequestedItem) {
       nextEntries.add(entry);
       continue;
     }
@@ -148,8 +206,44 @@ Bag _consumeOnePotionOrThrow(Bag bag) {
 
   if (!consumed) {
     throw StateError(
-        'Impossible de consommer Potion : aucune entrée potion disponible.');
+      'Impossible de consommer ${itemSpec.label} : aucune entrée '
+      '${itemSpec.itemId} disponible.',
+    );
   }
 
   return Bag(entries: nextEntries).normalized();
 }
+
+_RuntimeBattleBagHpHealItemSpec _runtimeItemSpec(
+  BattleBagHpHealItemKind kind,
+) {
+  return switch (kind) {
+    BattleBagHpHealItemKind.potion => const _RuntimeBattleBagHpHealItemSpec(
+        kind: BattleBagHpHealItemKind.potion,
+        itemId: 'potion',
+        label: 'Potion',
+        healAmount: _runtimeBattlePotionHealAmount,
+      ),
+    BattleBagHpHealItemKind.superPotion =>
+      const _RuntimeBattleBagHpHealItemSpec(
+        kind: BattleBagHpHealItemKind.superPotion,
+        itemId: 'super-potion',
+        label: 'Super Potion',
+        healAmount: _runtimeBattleSuperPotionHealAmount,
+      ),
+  };
+}
+
+class _RuntimeBattleBagHpHealItemSpec {
+  const _RuntimeBattleBagHpHealItemSpec({
+    required this.kind,
+    required this.itemId,
+    required this.label,
+    required this.healAmount,
+  });
+
+  final BattleBagHpHealItemKind kind;
+  final String itemId;
+  final String label;
+  final int healAmount;
+}
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
index 16138b7c..65a81ee3 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
@@ -234,7 +234,15 @@ BattleBagItemKind _classifyBagItem(BagEntry bagEntry) {
 }
 
 bool _isSupportedMedicine(BagEntry bagEntry) {
-  return bagEntry.itemId == 'potion' && bagEntry.categoryId == 'medicine';
+  // Lot 9-f factorise ici le strict minimum utile :
+  // - `potion`
+  // - `super-potion`
+  //
+  // On ne bascule pas vers un registre d'items ni vers un catalogue runtime.
+  if (bagEntry.categoryId != 'medicine') {
+    return false;
+  }
+  return bagEntry.itemId == 'potion' || bagEntry.itemId == 'super-potion';
 }
 
 BattleBagMenuDisabledReason _captureDisabledReason({
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
index 661a96d0..e28852ff 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
@@ -56,7 +56,7 @@ List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
           turnResult.fieldEvents.isNotEmpty ||
           turnResult.stealthRockEvents.isNotEmpty ||
           turnResult.spikesEvents.isNotEmpty ||
-          turnResult.potionEvents.isNotEmpty ||
+          turnResult.bagHpHealItemEvents.isNotEmpty ||
           turnResult.switchEvents.isNotEmpty)) {
     throw StateError(
       'BattleTurnResult.timeline est requis pour afficher honnêtement la chronologie du tour dans l’overlay runtime.',
@@ -66,9 +66,11 @@ List<String> buildBattleTurnLinesForOverlay(BattleTurnResult turnResult) {
   final lines = <String>[];
   for (final event in turnResult.timeline) {
     switch (event) {
-      case BattleTurnPotionEvent(:final event):
+      case BattleTurnBagHpHealItemEvent(:final event):
         final actor = _overlayCombatantLabelForSide(event.side);
-        lines.add('$actor utilise Potion sur ${event.targetSpeciesId}');
+        lines.add(
+          '$actor utilise ${event.itemKind.label} sur ${event.targetSpeciesId}',
+        );
         lines.add('${event.targetSpeciesId} récupère ${event.healedAmount} PV');
       case BattleTurnExecutionEvent(:final execution):
         final attacker = _overlayCombatantLabelForSide(execution.attackerSide);
@@ -179,8 +181,11 @@ String buildBattleMedicineTargetPromptForOverlay(
   if (feedbackMessage != null && feedbackMessage.isNotEmpty) {
     return feedbackMessage;
   }
-  if (medicineTargetMenuModel.itemId == 'potion') {
-    return 'Choisis une cible pour Potion.';
+  final supportedItemLabel = _overlaySupportedMedicineLabel(
+    medicineTargetMenuModel.itemId,
+  );
+  if (supportedItemLabel != null) {
+    return 'Choisis une cible pour $supportedItemLabel.';
   }
   return 'Choisis un Pokémon.';
 }
@@ -321,6 +326,14 @@ String _overlayCombatantLabelForSide(BattleSideId side) {
   return side == BattleSideId.player ? 'Joueur' : 'Ennemi';
 }
 
+String? _overlaySupportedMedicineLabel(String itemId) {
+  return switch (itemId) {
+    'potion' => 'Potion',
+    'super-potion' => 'Super Potion',
+    _ => null,
+  };
+}
+
 String _overlayWeatherLabel(BattleWeatherId weather) {
   return switch (weather) {
     BattleWeatherId.rain => 'la pluie',
@@ -360,7 +373,7 @@ class BattleOverlayComponent extends PositionComponent {
     required BattleSession session,
     required Vector2 viewportSize,
     required this.onPlayerChoice,
-    this.onPotionUseRequested,
+    this.onBagHpHealItemUseRequested,
     GameState gameState = const GameState(saveId: 'battle-overlay'),
     this.backgroundSpec = const BattleBackgroundSpec.fallbackField(),
     this.spriteResolver,
@@ -379,7 +392,10 @@ class BattleOverlayComponent extends PositionComponent {
   GameState _gameState;
 
   final void Function(PlayerBattleChoice choice) onPlayerChoice;
-  final bool Function(BattleMedicineTargetEntry entry)? onPotionUseRequested;
+  final bool Function(
+    BattleBagMenuActionMedicineTarget action,
+    BattleMedicineTargetEntry entry,
+  )? onBagHpHealItemUseRequested;
   final BattleBackgroundSpec backgroundSpec;
   final BattlePokemonSpriteResolver? spriteResolver;
   final BattleVisualAssetCache? visualAssetCache;
@@ -1089,16 +1105,17 @@ class BattleOverlayComponent extends PositionComponent {
     }
     final selectedMedicineAction = _selectedMedicineAction;
     if (selectedMedicineAction == null ||
-        selectedMedicineAction.itemId != 'potion') {
+        _overlaySupportedMedicineLabel(selectedMedicineAction.itemId) == null) {
       return false;
     }
 
-    // Lot 9-e change volontairement le propriétaire de l'effet réel :
-    // - le parent runtime commit maintenant un vrai tour `Potion` ;
+    // Lots 9-e / 9-f gardent l'overlay strictement borné au shell de ciblage :
+    // - le parent runtime commit le vrai tour pour `Potion` / `Super Potion` ;
     // - l'overlay ne patche plus sa session localement ;
     // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
     //   propriétaire unique du vrai BattleSession / GameState.
-    return onPotionUseRequested?.call(entry) ?? false;
+    return onBagHpHealItemUseRequested?.call(selectedMedicineAction, entry) ??
+        false;
   }
 
   void _handleBagEntrySelected(BattleBagMenuEntry entry) {
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart b/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
index c7658682..b2934427 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart
@@ -34,11 +34,12 @@ List<BattleTurnPresentationStep> buildBattleTurnPresentationSteps({
 
   for (final event in turnResult.timeline) {
     switch (event) {
-      case BattleTurnPotionEvent(:final event):
+      case BattleTurnBagHpHealItemEvent(:final event):
         final userLabel = _presentationCombatantLabel(event.side);
         steps.add(
           BattleTurnPresentationStep(
-            message: '$userLabel utilise Potion sur ${event.targetSpeciesId} !',
+            message:
+                '$userLabel utilise ${event.itemKind.label} sur ${event.targetSpeciesId} !',
           ),
         );
 
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 3089d31b..2b6ea93f 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -57,6 +57,7 @@ import '../../application/story_flags_manager.dart';
 import '../../application/trainer_battle_request.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../infrastructure/tile_image_loader.dart';
+import 'battle_bag_menu_model.dart';
 import 'battle_overlay_component.dart';
 import 'battle_background_resolver.dart';
 import 'battle_medicine_target_menu_model.dart';
@@ -3864,7 +3865,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           visualAssetCache: _battleVisualAssetCache,
           genderResolver: genderResolver,
           onPlayerChoice: _onPlayerBattleChoice,
-          onPotionUseRequested: _onBattlePotionUseRequested,
+          onBagHpHealItemUseRequested: _onBattleBagHpHealItemUseRequested,
         ),
       );
       camera.viewport.add(overlay);
@@ -3972,7 +3973,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
   }
 
-  bool _onBattlePotionUseRequested(
+  bool _onBattleBagHpHealItemUseRequested(
+    BattleBagMenuActionMedicineTarget action,
     BattleMedicineTargetEntry entry,
   ) {
     final battleSession = _battleSession;
@@ -3982,22 +3984,32 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     }
 
     if (_isBattleResolving) {
-      debugPrint('[battle] potion ignored: already resolving');
+      debugPrint('[battle] bag hp-heal item ignored: already resolving');
       return false;
     }
 
     _isBattleResolving = true;
     try {
-      // Lot 9-e fait maintenant passer Potion par un vrai commit de tour :
+      // Lots 9-e / 9-f gardent `PlayableMapGame` comme propriétaire honnête
+      // du runtime autour du moteur battle :
       // - le moteur battle produit un `currentTurn` et une timeline honnêtes ;
       // - le runtime reste propriétaire du bag réel et du write-back party ;
-      // - on n'ouvre toujours aucun PlayerBattleChoice item générique.
-      final result = tryApplyRuntimeBattlePotionUse(
-        session: battleSession,
-        gameState: _gameState,
-        context: activeBattleContext,
-        targetLineupIndex: entry.lineupIndex,
-      );
+      // - on reste borné à `Potion` + `Super Potion`, sans API item générique.
+      final result = switch (action.itemId) {
+        'potion' => tryApplyRuntimeBattlePotionUse(
+            session: battleSession,
+            gameState: _gameState,
+            context: activeBattleContext,
+            targetLineupIndex: entry.lineupIndex,
+          ),
+        'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
+            session: battleSession,
+            gameState: _gameState,
+            context: activeBattleContext,
+            targetLineupIndex: entry.lineupIndex,
+          ),
+        _ => null,
+      };
       if (result == null) {
         return false;
       }
diff --git a/packages/map_runtime/test/battle_bag_menu_model_test.dart b/packages/map_runtime/test/battle_bag_menu_model_test.dart
index fa23a43a..451f4a3d 100644
--- a/packages/map_runtime/test/battle_bag_menu_model_test.dart
+++ b/packages/map_runtime/test/battle_bag_menu_model_test.dart
@@ -395,6 +395,60 @@ void main() {
       );
     });
 
+    test(
+        'supported super potion is selectable in a free turn and opens a medicine target action',
+        () {
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'wildmon',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+        ),
+        allowCapture: true,
+      );
+
+      final model = buildBattleBagMenuModel(
+        gameState: _gameState(
+          bag: Bag(
+            entries: <BagEntry>[
+              _entry(
+                itemId: 'super-potion',
+                categoryId: 'medicine',
+                quantity: 2,
+              ),
+            ],
+          ),
+        ),
+        session: session,
+      );
+
+      final entry = model.entries.single;
+      expect(entry.kind, equals(BattleBagItemKind.medicine));
+      expect(entry.quantity, equals(2));
+      expect(entry.isSelectable, isTrue);
+      expect(entry.disabledReason, isNull);
+      expect(
+        entry.action,
+        isA<BattleBagMenuActionMedicineTarget>()
+            .having(
+              (action) => action.itemId,
+              'itemId',
+              equals('super-potion'),
+            )
+            .having(
+              (action) => action.categoryId,
+              'categoryId',
+              equals('medicine'),
+            )
+            .having((action) => action.quantity, 'quantity', equals(2)),
+      );
+    });
+
     test('unsupported medicine stays visible but disabled', () {
       final session = _session(
         player: _combatant(
diff --git a/packages/map_runtime/test/battle_overlay_component_test.dart b/packages/map_runtime/test/battle_overlay_component_test.dart
index f793cc7b..ecce6894 100644
--- a/packages/map_runtime/test/battle_overlay_component_test.dart
+++ b/packages/map_runtime/test/battle_overlay_component_test.dart
@@ -1333,29 +1333,54 @@ void main() {
         gameState: gameState,
         viewportSize: Vector2(960, 540),
         onPlayerChoice: (choice) => pickedChoice = choice,
-        onPotionUseRequested: (entry) {
-          final result = tryApplyRuntimeBattlePotionUse(
-            session: overlay.debugSession,
-            gameState: overlay.debugGameState,
-            context: const RuntimeActiveBattleContext(
-              request: TrainerBattleStartRequest(
-                requestId: 'trainer-request',
-                createdAtEpochMs: 1,
-                returnContext: OverworldReturnContext(
-                  mapId: 'field_map',
-                  playerPos: GridPos(x: 1, y: 1),
-                  playerFacing: Direction.north,
+        onBagHpHealItemUseRequested: (action, entry) {
+          final result = switch (action.itemId) {
+            'potion' => tryApplyRuntimeBattlePotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[0, 1],
                 ),
-                trainerId: 'trainer',
-                npcEntityId: 'npc_trainer',
-                mapId: 'field_map',
-                playerPos: GridPos(x: 1, y: 1),
+                targetLineupIndex: entry.lineupIndex,
               ),
-              playerPartyIndex: 0,
-              playerPartySlotIndicesByLineupIndex: <int>[0, 1],
-            ),
-            targetLineupIndex: entry.lineupIndex,
-          );
+            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[0, 1],
+                ),
+                targetLineupIndex: entry.lineupIndex,
+              ),
+            _ => null,
+          };
           if (result == null) {
             return false;
           }
@@ -1381,7 +1406,11 @@ void main() {
       expect(overlay.debugSession.state.currentTurn, isNotNull);
       expect(
         overlay.debugSession.state.currentTurn!.playerAction,
-        isA<BattleActionPotionUse>(),
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.potion),
+        ),
       );
       expect(overlay.debugSession.state.player.currentHp, equals(32));
       expect(overlay.debugGameState.party.members.first.currentHp, equals(32));
@@ -1440,29 +1469,54 @@ void main() {
         ),
         viewportSize: Vector2(960, 540),
         onPlayerChoice: (choice) => pickedChoice = choice,
-        onPotionUseRequested: (entry) {
-          final result = tryApplyRuntimeBattlePotionUse(
-            session: overlay.debugSession,
-            gameState: overlay.debugGameState,
-            context: const RuntimeActiveBattleContext(
-              request: TrainerBattleStartRequest(
-                requestId: 'trainer-request',
-                createdAtEpochMs: 1,
-                returnContext: OverworldReturnContext(
-                  mapId: 'field_map',
-                  playerPos: GridPos(x: 1, y: 1),
-                  playerFacing: Direction.north,
+        onBagHpHealItemUseRequested: (action, entry) {
+          final result = switch (action.itemId) {
+            'potion' => tryApplyRuntimeBattlePotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[1, 0],
                 ),
-                trainerId: 'trainer',
-                npcEntityId: 'npc_trainer',
-                mapId: 'field_map',
-                playerPos: GridPos(x: 1, y: 1),
+                targetLineupIndex: entry.lineupIndex,
               ),
-              playerPartyIndex: 0,
-              playerPartySlotIndicesByLineupIndex: <int>[1, 0],
-            ),
-            targetLineupIndex: entry.lineupIndex,
-          );
+            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[1, 0],
+                ),
+                targetLineupIndex: entry.lineupIndex,
+              ),
+            _ => null,
+          };
           if (result == null) {
             return false;
           }
@@ -1489,7 +1543,11 @@ void main() {
       expect(overlay.debugSession.state.currentTurn, isNotNull);
       expect(
         overlay.debugSession.state.currentTurn!.playerAction,
-        isA<BattleActionPotionUse>(),
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.potion),
+        ),
       );
       expect(overlay.debugSession.state.player.currentHp, equals(22));
       expect(
@@ -1503,6 +1561,139 @@ void main() {
       expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
     });
 
+    test(
+        'selecting a valid super potion target commits a real turn without dispatching a PlayerBattleChoice',
+        () async {
+      PlayerBattleChoice? pickedChoice;
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 22,
+          maxHp: 90,
+          moves: <BattleMoveData>[_tackle()],
+        ),
+        enemy: _combatant(
+          speciesId: 'wild_enemy',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_waitingMove()],
+        ),
+      );
+      final gameState = _gameState(
+        bag: Bag(
+          entries: <BagEntry>[
+            _bagEntry(
+              itemId: 'super-potion',
+              categoryId: 'medicine',
+              quantity: 1,
+            ),
+          ],
+        ),
+        partyMembers: <PlayerPokemon>[
+          _partyMember(speciesId: 'sproutle', currentHp: 22),
+        ],
+      );
+      late BattleOverlayComponent overlay;
+      overlay = BattleOverlayComponent(
+        session: session,
+        gameState: gameState,
+        viewportSize: Vector2(960, 540),
+        onPlayerChoice: (choice) => pickedChoice = choice,
+        onBagHpHealItemUseRequested: (action, entry) {
+          final result = switch (action.itemId) {
+            'potion' => tryApplyRuntimeBattlePotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[0],
+                ),
+                targetLineupIndex: entry.lineupIndex,
+              ),
+            'super-potion' => tryApplyRuntimeBattleSuperPotionUse(
+                session: overlay.debugSession,
+                gameState: overlay.debugGameState,
+                context: const RuntimeActiveBattleContext(
+                  request: TrainerBattleStartRequest(
+                    requestId: 'trainer-request',
+                    createdAtEpochMs: 1,
+                    returnContext: OverworldReturnContext(
+                      mapId: 'field_map',
+                      playerPos: GridPos(x: 1, y: 1),
+                      playerFacing: Direction.north,
+                    ),
+                    trainerId: 'trainer',
+                    npcEntityId: 'npc_trainer',
+                    mapId: 'field_map',
+                    playerPos: GridPos(x: 1, y: 1),
+                  ),
+                  playerPartyIndex: 0,
+                  playerPartySlotIndicesByLineupIndex: <int>[0],
+                ),
+                targetLineupIndex: entry.lineupIndex,
+              ),
+            _ => null,
+          };
+          if (result == null) {
+            return false;
+          }
+          overlay.updateState(
+            result.updatedSession,
+            gameState: result.updatedGameState,
+          );
+          return true;
+        },
+      );
+
+      await overlay.onLoad();
+
+      overlay.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
+      expect(overlay.validateSelectedChoice(), isTrue);
+
+      await overlay.waitForPendingVisualSync();
+
+      expect(pickedChoice, isNull);
+      expect(overlay.debugSession.state.currentTurn, isNotNull);
+      expect(
+        overlay.debugSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.superPotion),
+        ),
+      );
+      expect(overlay.debugSession.state.player.currentHp, equals(72));
+      expect(overlay.debugGameState.party.members.first.currentHp, equals(72));
+      expect(overlay.debugGameState.bag.entries, isEmpty);
+      expect(overlay.isTurnPresentationActive, isTrue);
+      expect(
+        overlay.currentPromptText,
+        equals('Joueur utilise Super Potion sur sproutle !'),
+      );
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+      expect(overlay.validateSelectedChoice(), isFalse);
+
+      overlay.updateTree(0.50);
+      expect(overlay.currentPromptText, equals('sproutle récupère 50 PV.'));
+    });
+
     test('full hp medicine targets stay visible but non-selectable', () async {
       final overlay = BattleOverlayComponent(
         session: _session(
diff --git a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
index 1781e72d..c71dd515 100644
--- a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
+++ b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
@@ -160,7 +160,11 @@ void main() {
       expect(result.updatedSession.state.currentTurn, isNotNull);
       expect(
         result.updatedSession.state.currentTurn!.playerAction,
-        isA<BattleActionPotionUse>(),
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.potion),
+        ),
       );
       expect(result.updatedSession.state.player.currentHp, equals(32));
       expect(result.updatedGameState.party.members.first.currentHp, equals(32));
@@ -212,6 +216,115 @@ void main() {
       expect(result.updatedGameState.party.members.first.currentHp, equals(40));
     });
 
+    test(
+        'super potion heals a damaged active target by 50 and consumes only super potion',
+        () {
+      final result = tryApplyRuntimeBattleSuperPotionUse(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 12,
+            maxHp: 80,
+            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+          ),
+          enemy: _combatant(
+            speciesId: 'enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
+          ),
+        ),
+        gameState: _gameState(
+          bag: const Bag(
+            entries: <BagEntry>[
+              BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
+              BagEntry(
+                itemId: 'super-potion',
+                categoryId: 'medicine',
+                quantity: 2,
+              ),
+            ],
+          ),
+          partyMembers: <PlayerPokemon>[
+            _partyMember(speciesId: 'sproutle', currentHp: 12, level: 10),
+          ],
+        ),
+        context: _context(
+          playerPartyIndex: 0,
+          lineupPartyIndices: const <int>[0],
+        ),
+        targetLineupIndex: 0,
+      );
+
+      expect(result, isNotNull);
+      expect(result!.healedAmount, equals(50));
+      expect(
+        result.updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.superPotion),
+        ),
+      );
+      expect(result.updatedSession.state.player.currentHp, equals(62));
+      expect(result.updatedGameState.party.members.first.currentHp, equals(62));
+      expect(
+        result.updatedGameState.bag.entries,
+        const <BagEntry>[
+          BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
+          BagEntry(
+            itemId: 'super-potion',
+            categoryId: 'medicine',
+            quantity: 1,
+          ),
+        ],
+      );
+    });
+
+    test('super potion heal is capped at max hp', () {
+      final result = tryApplyRuntimeBattleSuperPotionUse(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 60,
+            maxHp: 80,
+            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+          ),
+          enemy: _combatant(
+            speciesId: 'enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
+          ),
+        ),
+        gameState: _gameState(
+          bag: const Bag(
+            entries: <BagEntry>[
+              BagEntry(
+                itemId: 'super-potion',
+                categoryId: 'medicine',
+                quantity: 1,
+              ),
+            ],
+          ),
+          partyMembers: <PlayerPokemon>[
+            _partyMember(speciesId: 'sproutle', currentHp: 60),
+          ],
+        ),
+        context: _context(
+          playerPartyIndex: 0,
+          lineupPartyIndices: const <int>[0],
+        ),
+        targetLineupIndex: 0,
+      );
+
+      expect(result, isNotNull);
+      expect(result!.healedAmount, equals(20));
+      expect(result.updatedSession.state.player.currentHp, equals(80));
+      expect(result.updatedGameState.party.members.first.currentHp, equals(80));
+      expect(result.updatedGameState.bag.entries, isEmpty);
+    });
+
     test(
         'potion use removes the bag entry when quantity reaches zero and targets the intended reserve by lineup identity',
         () {
diff --git a/packages/map_runtime/test/battle_turn_presentation_test.dart b/packages/map_runtime/test/battle_turn_presentation_test.dart
index 81f30124..8ab88b17 100644
--- a/packages/map_runtime/test/battle_turn_presentation_test.dart
+++ b/packages/map_runtime/test/battle_turn_presentation_test.dart
@@ -275,7 +275,8 @@ void main() {
         ),
       );
       const turn = BattleTurnResult(
-        playerAction: BattleActionPotionUse(
+        playerAction: BattleActionBagHpHealItemUse(
+          itemKind: BattleBagHpHealItemKind.potion,
           targetLineupIndex: 0,
           healAmount: 20,
         ),
@@ -303,8 +304,9 @@ void main() {
             didHit: true,
           ),
         ],
-        potionEvents: <BattlePotionEvent>[
-          BattlePotionEvent(
+        bagHpHealItemEvents: <BattleBagHpHealItemEvent>[
+          BattleBagHpHealItemEvent(
+            itemKind: BattleBagHpHealItemKind.potion,
             side: BattleSideId.player,
             targetLineupIndex: 0,
             targetSpeciesId: 'sproutle',
@@ -313,8 +315,9 @@ void main() {
           ),
         ],
         timeline: <BattleTurnEvent>[
-          BattleTurnPotionEvent(
-            BattlePotionEvent(
+          BattleTurnBagHpHealItemEvent(
+            BattleBagHpHealItemEvent(
+              itemKind: BattleBagHpHealItemKind.potion,
               side: BattleSideId.player,
               targetLineupIndex: 0,
               targetSpeciesId: 'sproutle',
@@ -359,6 +362,112 @@ void main() {
       expect(steps[2].hpTo, equals(23));
     });
 
+    test(
+        'renders super potion use as a committed turn step before the enemy response',
+        () {
+      final beforeSession = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          maxHp: 80,
+          currentHp: 12,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'sparkitten',
+          lineupIndex: 0,
+          maxHp: 50,
+          currentHp: 50,
+          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+        ),
+      );
+      const turn = BattleTurnResult(
+        playerAction: BattleActionBagHpHealItemUse(
+          itemKind: BattleBagHpHealItemKind.superPotion,
+          targetLineupIndex: 0,
+          healAmount: 50,
+        ),
+        enemyAction: BattleActionFight(
+          BattleMove(
+            id: 'scratch',
+            name: 'Scratch',
+            power: 35,
+            target: BattleMoveTarget.opponent,
+          ),
+          moveIndex: 0,
+        ),
+        executions: <BattleMoveExecution>[
+          BattleMoveExecution(
+            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
+            move: BattleMove(
+              id: 'scratch',
+              name: 'Scratch',
+              power: 35,
+              target: BattleMoveTarget.opponent,
+            ),
+            targetKind: BattleMoveExecutionTargetKind.combatant,
+            targetSlot: BattleSlotRef.active(BattleSideId.player),
+            damage: 9,
+            didHit: true,
+          ),
+        ],
+        bagHpHealItemEvents: <BattleBagHpHealItemEvent>[
+          BattleBagHpHealItemEvent(
+            itemKind: BattleBagHpHealItemKind.superPotion,
+            side: BattleSideId.player,
+            targetLineupIndex: 0,
+            targetSpeciesId: 'sproutle',
+            hpBefore: 12,
+            hpAfter: 62,
+          ),
+        ],
+        timeline: <BattleTurnEvent>[
+          BattleTurnBagHpHealItemEvent(
+            BattleBagHpHealItemEvent(
+              itemKind: BattleBagHpHealItemKind.superPotion,
+              side: BattleSideId.player,
+              targetLineupIndex: 0,
+              targetSpeciesId: 'sproutle',
+              hpBefore: 12,
+              hpAfter: 62,
+            ),
+          ),
+          BattleTurnExecutionEvent(
+            BattleMoveExecution(
+              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
+              move: BattleMove(
+                id: 'scratch',
+                name: 'Scratch',
+                power: 35,
+                target: BattleMoveTarget.opponent,
+              ),
+              targetKind: BattleMoveExecutionTargetKind.combatant,
+              targetSlot: BattleSlotRef.active(BattleSideId.player),
+              damage: 9,
+              didHit: true,
+            ),
+          ),
+        ],
+      );
+
+      final steps = buildBattleTurnPresentationSteps(
+        playerBefore: beforeSession.state.player,
+        enemyBefore: beforeSession.state.enemy,
+        turnResult: turn,
+      );
+
+      expect(steps, hasLength(3));
+      expect(
+        steps[0].message,
+        equals('Joueur utilise Super Potion sur sproutle !'),
+      );
+      expect(steps[1].message, equals('sproutle récupère 50 PV.'));
+      expect(steps[1].hpFrom, equals(12));
+      expect(steps[1].hpTo, equals(62));
+      expect(steps[2].hpFrom, equals(62));
+      expect(steps[2].hpTo, equals(53));
+    });
+
     test('keeps status-like executions as message-only steps', () {
       final beforeSession = _session(
         player: _combatant(
diff --git a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
index aede580f..a4134a02 100644
--- a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
+++ b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
@@ -602,10 +602,136 @@ void main() {
       expect(currentTurn, isNotNull);
       expect(
         currentTurn!.playerAction,
-        isA<BattleActionPotionUse>(),
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.potion),
+        ),
+      );
+      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
+      expect(
+        currentTurn.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.potion),
+      );
+      expect(
+        currentTurn.bagHpHealItemEvents.single.hpAfter,
+        equals(expectedHealedHp),
+      );
+      expect(
+        game.debugBattleSessionSnapshot!.state.player.currentHp,
+        lessThanOrEqualTo(expectedHealedHp),
+      );
+      expect(
+        game.gameStateSnapshot.party.members.first.currentHp,
+        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
+      );
+      expect(game.gameStateSnapshot.bag.entries, isEmpty);
+    });
+
+    test('battle BAG super potion use persists to PlayableMapGame state',
+        () async {
+      final manifest = await _writeProjectManifest(tempProjectRoot);
+      final map = _buildMap();
+      final world = GameplayWorldState.fromMap(
+        map,
+        project: manifest,
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+      final movedWorld = stepGameplayWorld(
+        world,
+        const MoveIntent(Direction.east),
+      ).world;
+      final encounter = checkEncounterAtPlayerPosition(
+        world: movedWorld,
+        project: manifest,
+        encounterKind: EncounterKind.walk,
+        random: _FixedEncounterRandom(
+          nextDoubleValues: const <double>[0.0],
+          nextIntValues: const <int>[0, 0],
+        ),
+        policy: const GameplayEncounterPolicy(chancePerStep: 1),
+      ).encounter!;
+      final request = buildBattleStartRequestFromEncounter(
+        encounter: encounter,
+        world: movedWorld,
+        createdAtEpochMs: 1,
+      );
+
+      const initialState = GameState(
+        saveId: 'wild-flow-super-potion-save',
+        bag: Bag(
+          entries: <BagEntry>[
+            BagEntry(
+              itemId: 'super-potion',
+              categoryId: 'medicine',
+              quantity: 1,
+            ),
+          ],
+        ),
+        party: PlayerParty(
+          members: <PlayerPokemon>[
+            PlayerPokemon(
+              speciesId: 'sproutle',
+              natureId: 'bold',
+              abilityId: 'overgrow',
+              level: 10,
+              knownMoveIds: <String>['vine_whip'],
+              currentHp: 12,
+            ),
+          ],
+        ),
+      );
+
+      final game = PlayableMapGame(
+        bundle: _buildBundle(tempProjectRoot.path, manifest, map),
+        projectFilePath: p.join(tempProjectRoot.path, 'project.json'),
+        saveData: saveDataFromGameState(initialState),
+      );
+      game.onGameResize(Vector2(640, 480));
+      await game.onLoad();
+
+      await game.debugOpenBattleForTest(request);
+      await game.debugWaitForBattleOverlaySync();
+
+      final overlay = game.debugBattleOverlayComponent;
+      expect(overlay, isNotNull);
+      expect(game.debugBattleSessionSnapshot, isNotNull);
+      final initialBattleHp =
+          game.debugBattleSessionSnapshot!.state.player.currentHp;
+      final initialBattleMaxHp =
+          game.debugBattleSessionSnapshot!.state.player.maxHp;
+      final expectedHealedHp = min(initialBattleHp + 50, initialBattleMaxHp);
+
+      overlay!.moveSelectionRight();
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bagMedicineTarget);
+      expect(overlay.validateSelectedChoice(), isTrue);
+      await game.debugWaitForBattleOverlaySync();
+
+      expect(game.debugFlowPhaseName, equals('battle'));
+      expect(game.debugBattleSessionSnapshot, isNotNull);
+      final currentTurn = game.debugBattleSessionSnapshot!.state.currentTurn;
+      expect(currentTurn, isNotNull);
+      expect(
+        currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.superPotion),
+        ),
+      );
+      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
+      expect(
+        currentTurn.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.superPotion),
+      );
+      expect(
+        currentTurn.bagHpHealItemEvents.single.hpAfter,
+        equals(expectedHealedHp),
       );
-      expect(currentTurn.potionEvents, hasLength(1));
-      expect(currentTurn.potionEvents.single.hpAfter, equals(expectedHealedHp));
       expect(
         game.debugBattleSessionSnapshot!.state.player.currentHp,
         lessThanOrEqualTo(expectedHealedHp),

```
