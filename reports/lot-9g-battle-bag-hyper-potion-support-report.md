# Lot 9-g — Battle BAG hyper potion support

## Résumé exécutif
Le lot 9-g ajoute `hyper-potion` au fil BAG battle déjà honnête de `Potion + Super Potion`, sans ouvrir de système générique d'items battle.

Le choix retenu est **l'extension bornée de la mini-factorisation 9-f** :
- côté `map_battle`, la famille fermée `BattleBagHpHealItemKind` passe de 2 à 3 cas ;
- côté runtime, le seam historique est **renommé** de `runtime_battle_potion_apply.dart` vers `runtime_battle_bag_hp_heal_item_apply.dart` ;
- côté overlay / runtime parent, `hyper-potion` réutilise le shell medicine existant, commit un vrai tour, produit une vraie timeline, soigne réellement et consomme la bonne entrée bag.

`Hyper Potion` soigne maintenant réellement, commit un vrai tour, laisse l'adversaire répondre dans le flow normal, et n'altère ni `Potion`, ni `Super Potion`, ni la capture 9-b.

## Confirmation de scope
Ce lot reste strictement dans le fil BAG runtime/UI/runtime/battle :
- aucune modification BDC-01 ;
- aucun changement du bridge runtime -> battle des moves ;
- aucun changement `Bubble` / `Bubble Beam` ;
- aucun changement du converter Showdown ;
- aucun registre d'items ;
- aucun système générique d'items battle ;
- aucune autre medicine que `potion`, `super-potion`, `hyper-potion`.

## Audit initial
### Rapports relus
- `/Users/karim/Project/pokemonProject/reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9b-battle-bag-capture-wiring-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9c-battle-bag-medicine-target-shell-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9d-battle-bag-potion-real-apply-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9e-battle-bag-potion-turn-commit-report.md`
- `/Users/karim/Project/pokemonProject/reports/lot-9f-battle-bag-super-potion-support-report.md`
- `/Users/karim/Project/pokemonProject/reports/battle-data-coverage-bdc-01-probabilistic-stat-riders-report.md`

### Fichiers audités en priorité
#### Battle
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`

#### Runtime
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### Contrats existants confirmés avant implémentation
- 9-f avait déjà une vraie action de tour bornée via `BattleActionBagHpHealItemUse` et `BattleBagHpHealItemKind`.
- 9-f avait déjà un commit honnête dans `BattleSession`, une timeline ordonnée, et une orchestration runtime réelle dans `PlayableMapGame`.
- `battle_turn_presentation.dart` était déjà générique sur `event.itemKind.label`, donc aucune extension de contrat n'était nécessaire pour raconter `Hyper Potion`.
- Le runtime restait propriétaire du bag réel et du write-back party, ce qu'il fallait préserver.
- `battle_bag_menu_model.dart` n'autorisait encore que `potion` et `super-potion`.
- `runtime_battle_potion_apply.dart` portait déjà un seam de fait multi-objets, avec un nom devenu historiquement trompeur après 9-f.

### Risques principaux identifiés à l'audit
- Étendre la mini-factorisation 9-f sans la laisser dériver vers un faux framework d'items.
- Éviter un `itemId` stringly-typed libre au cœur du moteur battle.
- Renommer le fichier runtime seulement si le gain de lisibilité dépassait clairement le churn.
- Ajouter `hyper-potion` sans régression sur `Potion`, `Super Potion`, capture 9-b, ni flow de tour déjà prouvé.

## Décision d'architecture
### Réponse à la question d'architecture du prompt
**Option retenue : Option B, extension bornée de la mini-factorisation actuelle vers `Potion + Super Potion + Hyper Potion`.**

Pourquoi ce choix est le plus petit seam honnête :
- Après 9-f, dupliquer encore une troisième fois le pipeline complet aurait créé de la répétition artificielle dans `map_battle`, `map_runtime`, les tests runtime, les tests overlay et les tests d'intégration.
- Le repo prouvait déjà qu'un seam fermé existe et reste sain : un enum borné côté battle, des façades explicites par objet côté runtime, et aucun `itemId` arbitraire dans le moteur.
- Étendre ce seam de 2 à 3 cas est plus petit, plus sûr et plus honnête qu'une duplication objet-par-objet devenue purement mécanique.

Comment le lot évite un framework d'items :
- `BattleBagHpHealItemKind` reste un type fermé à trois valeurs.
- `BattleActionBagHpHealItemUse` reste une action ultra-spécifique aux HP-heal items plats du BAG battle.
- Le runtime garde des façades par objet : `tryApplyRuntimeBattlePotionUse`, `tryApplyRuntimeBattleSuperPotionUse`, `tryApplyRuntimeBattleHyperPotionUse`.
- Aucun registre, aucun catalogue runtime, aucun parsing textuel, aucun `PlayerBattleChoiceUseItem` n'est introduit.

### Position explicite sur le renommage de `runtime_battle_potion_apply.dart`
**Oui, le renommage était justifié maintenant.**

Pourquoi maintenant est le bon moment :
- Après 9-f, le nom était déjà historiquement faux ; avec 9-g et un troisième objet, il devenait franchement mensonger.
- Le blast radius restait raisonnable : imports internes runtime + tests runtime seulement.
- Le gain de lisibilité dépasse maintenant clairement le churn, alors qu'en 9-f il était encore défendable de repousser.

Décision retenue :
- suppression de `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
- création de `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`

Compromis volontaire :
- je **n'ai pas** renommé le test historique `battle_potion_apply_runtime_test.dart` pour limiter le churn et conserver les commandes de validation explicites du prompt.

## Valeur de heal retenue pour `Hyper Potion`
Aucun canon local réutilisable pour `hyper-potion` n'a été trouvé dans le repo pendant l'audit.

Valeur retenue :
- `hyper-potion healAmount = 200`

Pourquoi :
- c'est exactement la valeur de fallback explicitement demandée par le prompt si aucun canon local n'existe ;
- elle reste cohérente avec les générations récentes de Pokémon ;
- elle est néanmoins **potentiellement discutable** si le projet décide plus tard de verrouiller une génération de référence plus ancienne.

## Regard critique explicite sur le prompt
### Points solides
- Le prompt borne bien le scope et interdit explicitement un framework générique d'items.
- La question de renommage du fichier runtime historique était pertinente et utile.
- L'exigence de critique du prompt lui-même est saine pour éviter le suivisme.

### Points discutables ou ajustés
1. **Le prompt cite encore `runtime_battle_potion_apply.dart` comme fichier à inspecter, alors que le lot lui-même demande d'auditer un éventuel renommage.**
   Le repo montrait qu'après 9-f, le nom était déjà trompeur. J'ai donc inspecté ce fichier, puis j'ai explicitement basculé vers son remplaçant renommé pour l'implémentation et la validation.

2. **La demande d'"état git initial exact" était difficile à satisfaire parfaitement dans cette continuation.**
   Cette session 9-g a repris sur un thread déjà en cours avec une worktree non propre et une passe RED déjà engagée. Plutôt que d'inventer un snapshot parfait, je documente ci-dessous l'**earliest reliable observed state** et j'explique honnêtement la limite.

3. **Le prompt suppose implicitement un repo déjà propre autour de 9-f.**
   En réalité, la worktree contenait aussi une dirtiness parallèle hors scope : renommages d'assets `fx/* -> packages/map_runtime/assets/fx/*`, modification de `packages/map_runtime/pubspec.yaml`, et un fichier downstream `examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart` visible dans l'état final. Je les ai explicitement exclus du slice 9-g.

## Sub-agents / passes
Des vrais sub-agents ont été tentés plus tôt dans le fil, mais l'environnement a répondu `agent thread limit reached (max 6)`. Je n'invente donc pas de faux sub-agents : j'ai exécuté des **passes locales nommées**.

- **Pass Audit / Architecture** : `OK`
  - verdict : l'extension bornée à trois objets et le renommage runtime sont le plus petit seam honnête.
- **Pass Implémentation** : `OK`
  - verdict : `hyper-potion` traverse correctement battle -> runtime -> overlay sans ouvrir de système générique.
- **Pass Tests** : `OK`
  - verdict : red pass prouvée, green pass ciblée et suites complètes vertes.
- **Pass Build / Validation** : `OK`
  - verdict : analyze et tests complets verts ; build package non applicable ; smoke test host vert.
- **Pass Critique finale** : `OK`
  - verdict : pas de scope creep détecté ; seuls risques résiduels bornés et documentés ci-dessous.

## État git initial
### Limite d'honnêteté
Je n'ai pas un snapshot pré-9-g absolument parfait figé avant toute action, parce que cette continuation a repris après une passe de tests rouges déjà engagée dans le même fil. Je documente donc **le plus ancien état git fiable observé pendant ce lot**.

### Earliest reliable observed git state pendant 9-g
Travail déjà sale hors scope / parallèle observé pendant ce lot :
- renommages `fx/* -> packages/map_runtime/assets/fx/*`
- modification de `/Users/karim/Project/pokemonProject/packages/map_runtime/pubspec.yaml`

Ces éléments ont été traités comme **préexistants hors scope**. Je n'y ai pas touché pour 9-g.

## Classification honnête de la dirtiness
### Preexisting out-of-scope / parallel dirty
- `fx/* -> /Users/karim/Project/pokemonProject/packages/map_runtime/assets/fx/*`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/pubspec.yaml`
- `/Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart`

Note d'honnêteté :
- ces entrées ont été **observées pendant le lot** comme dirtiness parallèle / hors scope ;
- elles n'apparaissent plus dans le `git status` final ci-dessous ;
- elles ne font donc pas partie du diff 9-g effectivement retenu à la fin.

### Modified by this lot
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
- `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### Created by this lot
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`
- `/Users/karim/Project/pokemonProject/reports/lot-9g-battle-bag-hyper-potion-support-report.md`

### Deleted by this lot
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`

## Fichiers touchés par le lot et impact attendu
1. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart`
   - zones modifiées : `BattleBagHpHealItemKind`, doc de `BattleActionBagHpHealItemUse`
   - raison : ajouter `hyperPotion` au type borné côté moteur
   - impact : le moteur continue de refuser tout `itemId` arbitraire tout en supportant un troisième objet explicite

2. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart`
   - zones modifiées : documentation de `BattleTurnResult.bagHpHealItemEvents`, `BattleBagHpHealItemEvent`
   - raison : réaligner les contrats et commentaires sur la famille à trois objets
   - impact : aucune logique nouvelle, mais documentation cohérente avec l'état réel du moteur

3. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart`
   - zones modifiées : façade `applyHyperPotionTurn`, commentaires d'architecture
   - raison : exposer un commit explicite pour `Hyper Potion` sans API générique
   - impact : `Hyper Potion` devient une vraie action de tour committée et timeline-visible

4. `/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session_scheduler.dart`
   - zones modifiées : commentaire de priorité locale
   - raison : documenter honnêtement la présence de trois BAG HP-heal items
   - impact : aucune logique de priorité nouvelle, juste une doc vraie

5. `/Users/karim/Project/pokemonProject/packages/map_battle/test/battle_session_test.dart`
   - zones modifiées : nouveau test `applyHyperPotionTurn...`
   - raison : prouver le vrai commit de tour moteur pour `Hyper Potion`
   - impact : verrouille la non-régression au niveau battle

6. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart`
   - zone touchée : suppression / remplacement
   - raison : nom devenu trop mensonger après extension à trois objets
   - impact : remplacé par un nom fidèle au seam réel

7. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`
   - zones modifiées : nouveau fichier complet, constante `200`, wrapper `tryApplyRuntimeBattleHyperPotionUse`, switch runtime, specs runtime, write-back bag/party
   - raison : renommer honnêtement le seam runtime et ajouter `Hyper Potion`
   - impact : le runtime applique réellement `Hyper Potion`, consomme la bonne entrée, et reste propriétaire du bag réel

8. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
   - zones modifiées : `_isSupportedMedicine`
   - raison : rendre `hyper-potion` sélectionnable dans le BAG battle
   - impact : le BAG propose le troisième objet dans les mêmes conditions que les deux précédents

9. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
   - zones modifiées : label overlay pour `hyper-potion`, commentaire de frontière du shell medicine
   - raison : narration / shell honnêtes pour `Hyper Potion`
   - impact : l'overlay sait nommer correctement l'objet et reste non-propriétaire de la vérité runtime

10. `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
    - zones modifiées : import du fichier runtime renommé, switch runtime BAG heal items, commentaires
    - raison : garder `PlayableMapGame` propriétaire du vrai runtime state
    - impact : `hyper-potion` déclenche la bonne mutation réelle `BattleSession + GameState`

11. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_bag_menu_model_test.dart`
    - zones modifiées : nouveau test `supported hyper potion...`
    - raison : prouver la sélection BAG 9-g et la non-régression des autres medicines
    - impact : verrouille l'ouverture du shell uniquement pour l'objet supporté

12. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_overlay_component_test.dart`
    - zones modifiées : mapping runtime callbacks, nouveau test `hyper potion`
    - raison : prouver le vrai commit overlay/runtime sans `PlayerBattleChoice`
    - impact : verrouille l'UX honnête et le non-retour à un second choix dans le même tour

13. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
    - zones modifiées : import du fichier renommé, nouveau groupe hyper potion, correction d'attente sur l'ordre de `Bag.normalized()`
    - raison : prouver le vrai runtime apply et éviter un faux test dépendant d'un ordre accidentel
    - impact : verrouille heal, cap, consommation et non-confusion avec `potion` / `super-potion`

14. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/battle_turn_presentation_test.dart`
    - zones modifiées : nouveau test `renders hyper potion use...`
    - raison : prouver la narration/timeline honnête de `Hyper Potion`
    - impact : verrouille la présentation sans changer le contrat existant

15. `/Users/karim/Project/pokemonProject/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
    - zones modifiées : nouveau test end-to-end `battle BAG hyper potion use persists...`
    - raison : prouver la synchronisation `PlayableMapGame` / overlay / session / `GameState`
    - impact : verrouille l'intégration parent runtime et la non-régression capture

## Tests créés ou modifiés
### Nouveaux / étendus
- `applyHyperPotionTurn commits a real turn and records a hyper potion timeline event`
- `supported hyper potion is selectable in a free turn and opens a medicine target action`
- `hyper potion heals a damaged active target by 200 and consumes only hyper potion`
- `hyper potion heal is capped at max hp`
- `renders hyper potion use as a committed turn step before the enemy response`
- `selecting a valid hyper potion target commits a real turn without dispatching a PlayerBattleChoice`
- `battle BAG hyper potion use persists to PlayableMapGame state`

### Red pass réellement observée
Commandes relancées avant implémentation complète :
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart`
  - résultat rouge observé : `BattleBagHpHealItemKind.hyperPotion` manquant ; `applyHyperPotionTurn` manquant
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_bag_menu_model_test.dart`
  - résultat rouge observé : `hyper-potion` encore non sélectionnable
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_potion_apply_runtime_test.dart`
  - résultat rouge observé : nouveau fichier runtime absent ; wrapper hyper potion absent ; enum battle incomplet
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_turn_presentation_test.dart`
  - résultat rouge observé : `BattleBagHpHealItemKind.hyperPotion` absent

## Commandes de test lancées et résultats exacts
### Ciblées
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_session_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_bag_menu_model_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_medicine_target_menu_model_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_potion_apply_runtime_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_turn_presentation_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/wild_battle_end_to_end_flow_test.dart`
  - résultat final : `All tests passed!`

### Suites complètes
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
  - résultat final : `All tests passed!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test`
  - résultat final : `All tests passed!`

## Commandes d'analyse lancées et résultats exacts
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze lib/src/battle_action.dart lib/src/battle_resolution.dart lib/src/battle_session.dart lib/src/battle_session_scheduler.dart test/battle_session_test.dart`
  - résultat final : `No issues found!`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart lib/src/presentation/flame/battle_bag_menu_model.dart lib/src/presentation/flame/battle_overlay_component.dart lib/src/presentation/flame/battle_turn_presentation.dart lib/src/presentation/flame/playable_map_game.dart test/battle_bag_menu_model_test.dart test/battle_medicine_target_menu_model_test.dart test/battle_overlay_component_test.dart test/battle_potion_apply_runtime_test.dart test/battle_turn_presentation_test.dart test/wild_battle_end_to_end_flow_test.dart`
  - résultat final : `No issues found! (ran in 1.6s)`

## Build / validation downstream
### Build package/app
Aucun `flutter build` autonome n'était applicable pour les packages directement touchés :
- `packages/map_battle` est une **lib Dart**, pas une app buildable seule ;
- `packages/map_runtime` est une **lib Flutter**, pas une app buildable seule.

La validation honnête pour ces packages est donc :
- `dart analyze` / `flutter analyze`
- tests ciblés
- suites complètes du package

### Host downstream pertinent
Un host buildable/consommateur direct existe et mérite un smoke test après le renommage runtime.

Commande lancée :
- `cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart`
  - résultat final : `All tests passed!`

## État git final
Cette section a été relevée **après** l'écriture du report, pour inclure le report lui-même.

```text
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
 M packages/map_battle/test/battle_session_test.dart
 D packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_bag_menu_model_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_potion_apply_runtime_test.dart
 M packages/map_runtime/test/battle_turn_presentation_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
 ?? packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
 ?? reports/lot-9g-battle-bag-hyper-potion-support-report.md
```

Diff stat du slice suivi par Git à ce moment :

```text
 packages/map_battle/lib/src/battle_action.dart     |  14 +-
 packages/map_battle/lib/src/battle_resolution.dart |  10 +-
 packages/map_battle/lib/src/battle_session.dart    |  23 +-
 .../lib/src/battle_session_scheduler.dart          |   5 +-
 packages/map_battle/test/battle_session_test.dart  |  71 ++++++
 .../application/runtime_battle_potion_apply.dart   | 249 ---------------------
 .../presentation/flame/battle_bag_menu_model.dart  |   7 +-
 .../flame/battle_overlay_component.dart            |   7 +-
 .../src/presentation/flame/playable_map_game.dart  |  13 +-
 .../test/battle_bag_menu_model_test.dart           |  54 +++++
 .../test/battle_overlay_component_test.dart        | 226 ++++++++++++++++++-
 .../test/battle_potion_apply_runtime_test.dart     | 127 ++++++++++-
 .../test/battle_turn_presentation_test.dart        | 106 +++++++++
 .../test/wild_battle_end_to_end_flow_test.dart     | 115 ++++++++++
 14 files changed, 755 insertions(+), 272 deletions(-)
```

## Limites explicitement conservées
- aucun système générique d'items battle
- aucun registre d'items
- aucun `itemId` arbitraire au cœur du moteur battle
- aucun `Antidote`
- aucun `Revive`
- aucun `Full Restore`
- aucun `X Attack`
- aucun held item
- aucune modification capture 9-b
- aucune modification BDC-01
- aucun changement du bridge runtime -> battle des moves
- aucun changement du converter Showdown
- aucune tentative de couvrir le catalogue global d'objets

## Auto-critique finale
### Risques restants
1. **La mini-famille bornée compte maintenant trois objets.**
   C'est toujours sain, mais si un futur lot ajoute encore un quatrième ou cinquième HP-heal item, il faudra refaire un audit explicite pour vérifier que la fermeture du type reste le meilleur choix.

2. **`hyper-potion = 200` est honnête mais génération-dépendant.**
   Le repo n'a pas de canon local ; j'ai donc suivi la valeur de fallback du prompt. Si le projet formalise plus tard une génération cible, il faudra peut-être réaligner cette valeur.

3. **Le test file `battle_potion_apply_runtime_test.dart` garde un nom historique.**
   Je l'ai laissé en place pour éviter du churn inutile sur les commandes de validation, mais le nom n'est plus parfaitement représentatif du contenu.

### Tests éventuellement encore intéressants plus tard
- un test dédié de non-régression sur l'ordre de narration `Hyper Potion` puis dégâts adverses pour une cible réserve, si une animation plus riche arrive plus tard
- un test explicite sur le refus d'ouvrir le shell medicine pour `hyper-potion` quand la request n'autorise pas le BAG, même si le comportement est déjà couvert par les seams existants

### Choix discutables assumés
- J'ai renommé le fichier runtime source maintenant, mais **pas** le test historique, pour maximiser le ratio lisibilité/gain sans multiplier le churn.
- Je n'ai pas touché `battle_turn_presentation.dart`, parce que le repo prouvait que le contrat y était déjà suffisamment générique ; j'ai préféré le prouver par test plutôt que d'éditer du code inutile.

### Pourquoi ce lot reste borné
- Le moteur battle ne reçoit toujours qu'un enum fermé à trois valeurs.
- Le runtime garde des façades par objet, pas une API libre par `itemId`.
- Le BAG model n'ouvre que trois ids précis.
- Aucune autre medicine ne devient supportée implicitement.

## Prochaines étapes proposées, sans implémentation
- décider explicitement si la mini-famille s'arrête à trois objets ou si un lot futur veut ajouter un quatrième HP-heal item avec un nouvel audit de bornage
- si plusieurs renommages historiques similaires s'accumulent, harmoniser le nommage des tests runtime anciens sans mélanger de scope fonctionnel
- seulement après un audit séparé, envisager un autre micro-slice battle honest item (par exemple une autre medicine très précise), sans jamais dériver vers un framework générique

## Appendice A — diff exhaustif des fichiers suivis modifiés/supprimés par le lot

```diff
diff --git a/packages/map_battle/lib/src/battle_action.dart b/packages/map_battle/lib/src/battle_action.dart
index d12cf536..9e3c5fd8 100644
--- a/packages/map_battle/lib/src/battle_action.dart
+++ b/packages/map_battle/lib/src/battle_action.dart
@@ -125,34 +125,38 @@ class BattleActionRun extends BattleAction {
 /// Lot 9-f factorise seulement ce qui devenait absurde à dupliquer :
 /// - `potion`
 /// - `super-potion`
+/// - `hyper-potion`
 ///
 /// Garde-fous de frontière :
 /// - ce n'est pas un catalogue runtime d'objets ;
 /// - ce n'est pas une taxonomie générale de medicines ;
-/// - aucune autre entrée (`antidote`, `hyper-potion`, `revive`, etc.)
+/// - aucune autre entrée (`antidote`, `revive`, etc.)
 ///   n'est implicite ou "préparée".
 enum BattleBagHpHealItemKind {
   potion,
-  superPotion;
+  superPotion,
+  hyperPotion;
 
   String get itemId => switch (this) {
         BattleBagHpHealItemKind.potion => 'potion',
         BattleBagHpHealItemKind.superPotion => 'super-potion',
+        BattleBagHpHealItemKind.hyperPotion => 'hyper-potion',
       };
 
   String get label => switch (this) {
         BattleBagHpHealItemKind.potion => 'Potion',
         BattleBagHpHealItemKind.superPotion => 'Super Potion',
+        BattleBagHpHealItemKind.hyperPotion => 'Hyper Potion',
       };
 }
 
 /// Utiliser un objet BAG de soin HP plat sur un membre du lineup joueur.
 ///
 /// Cette action reste volontairement très étroite :
-/// - elle couvre seulement `Potion` + `Super Potion` ;
+/// - elle couvre seulement `Potion` + `Super Potion` + `Hyper Potion` ;
 /// - elle ne lit jamais le bag ;
 /// - elle n'ouvre pas un système générique d'items battle ;
-/// - elle existe uniquement pour rendre ces deux objets honnêtes comme vraies
+/// - elle existe uniquement pour rendre ces trois objets honnêtes comme vraies
 ///   actions de tour committées et visibles dans la timeline.
 class BattleActionBagHpHealItemUse extends BattleAction {
   const BattleActionBagHpHealItemUse({
@@ -163,7 +167,7 @@ class BattleActionBagHpHealItemUse extends BattleAction {
 
   /// L'objet précis réellement utilisé.
   ///
-  /// Le `kind` reste borné à deux cas, ce qui évite de transporter un
+  /// Le `kind` reste borné à trois cas, ce qui évite de transporter un
   /// `itemId` stringly-typed arbitraire dans le moteur.
   final BattleBagHpHealItemKind itemKind;
 
diff --git a/packages/map_battle/lib/src/battle_resolution.dart b/packages/map_battle/lib/src/battle_resolution.dart
index 22109d0a..6fde7ab2 100644
--- a/packages/map_battle/lib/src/battle_resolution.dart
+++ b/packages/map_battle/lib/src/battle_resolution.dart
@@ -24,7 +24,8 @@ class BattleTurnResult {
   /// [fieldEvents] - Les événements de champ BE9 visibles du tour.
   /// [stealthRockEvents] - Les événements Stealth Rock visibles du tour.
   /// [spikesEvents] - Les événements Spikes visibles du tour.
-  /// [bagHpHealItemEvents] - Les usages visibles de Potion / Super Potion.
+  /// [bagHpHealItemEvents] - Les usages visibles de Potion / Super Potion /
+  /// Hyper Potion.
   /// [timeline] - La chronologie ordonnée réellement produite par le moteur.
   const BattleTurnResult({
     required this.playerAction,
@@ -103,7 +104,7 @@ class BattleTurnResult {
   /// Lot 9-f choisit une mini-factorisation bornée plutôt qu'une duplication
   /// intégrale du pipeline 9-e :
   /// - ce bucket ne devient pas `itemEvents` ;
-  /// - il ne couvre que `Potion` + `Super Potion` ;
+  /// - il ne couvre que `Potion` + `Super Potion` + `Hyper Potion` ;
   /// - toute autre medicine reste hors scope tant qu'un lot explicite ne la
   ///   branche pas réellement.
   final List<BattleBagHpHealItemEvent> bagHpHealItemEvents;
@@ -196,13 +197,14 @@ final class BattleTurnSwitchEvent extends BattleTurnEvent {
   final BattleSwitchEvent event;
 }
 
-/// Trace visible d'un vrai usage de `Potion` ou `Super Potion`.
+/// Trace visible d'un vrai usage de `Potion`, `Super Potion` ou
+/// `Hyper Potion`.
 ///
 /// La factorisation reste honnête parce qu'elle est bornée par
 /// [BattleBagHpHealItemKind] :
 /// - pas d'`itemId` arbitraire ;
 /// - pas de registre d'objets ;
-/// - seulement les données nécessaires pour raconter les deux objets de soin
+/// - seulement les données nécessaires pour raconter les trois objets de soin
 ///   HP plats réellement supportés à ce stade.
 final class BattleBagHpHealItemEvent {
   const BattleBagHpHealItemEvent({
diff --git a/packages/map_battle/lib/src/battle_session.dart b/packages/map_battle/lib/src/battle_session.dart
index 719f265b..9b3f1520 100644
--- a/packages/map_battle/lib/src/battle_session.dart
+++ b/packages/map_battle/lib/src/battle_session.dart
@@ -272,7 +272,8 @@ class BattleSession {
   ///
   /// Lot 9-f conserve cette façade explicite pour éviter de vendre une API
   /// générique d'objets : l'implémentation factorise en interne avec
-  /// `Super Potion`, mais l'appelant reste bien sur un objet concret.
+  /// `Super Potion` et `Hyper Potion`, mais l'appelant reste bien sur un
+  /// objet concret.
   BattleSession applyPotionTurn({
     required int targetLineupIndex,
     required int healAmount,
@@ -301,8 +302,26 @@ class BattleSession {
     );
   }
 
+  /// Commit une vraie action de tour `Hyper Potion`.
+  ///
+  /// Lot 9-g étend la mini-famille bornée sans franchir la frontière vers un
+  /// système générique :
+  /// - aucune autre medicine n'est implicitement supportée ;
+  /// - le scheduler et la timeline restent ceux déjà prouvés par 9-e/9-f ;
+  /// - l'appelant reste sur une façade explicite par objet.
+  BattleSession applyHyperPotionTurn({
+    required int targetLineupIndex,
+    required int healAmount,
+  }) {
+    return _applyBagHpHealItemTurn(
+      itemKind: BattleBagHpHealItemKind.hyperPotion,
+      targetLineupIndex: targetLineupIndex,
+      healAmount: healAmount,
+    );
+  }
+
   /// Commit une vraie action de tour pour la famille ultra-bornée
-  /// `Potion` + `Super Potion`.
+  /// `Potion` + `Super Potion` + `Hyper Potion`.
   ///
   /// Ce helper interne factorise seulement ce qui était devenu duplication :
   /// - même validation de requête ;
diff --git a/packages/map_battle/lib/src/battle_session_scheduler.dart b/packages/map_battle/lib/src/battle_session_scheduler.dart
index baa7f1b1..faedac7b 100644
--- a/packages/map_battle/lib/src/battle_session_scheduler.dart
+++ b/packages/map_battle/lib/src/battle_session_scheduler.dart
@@ -815,8 +815,9 @@ int _priorityForResolvedAction(BattleAction action) {
     // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
     //   des priorités de switch.
     //
-    // Lots 9-e / 9-f ajoutent un seul micro-slice d'objets :
-    // - `Potion` et `Super Potion` deviennent de vraies actions de tour ;
+    // Lots 9-e / 9-f / 9-g ajoutent un seul micro-slice d'objets :
+    // - `Potion`, `Super Potion` et `Hyper Potion` deviennent de vraies
+    //   actions de tour ;
     // - elles résolvent avant les moves actuellement supportés ;
     // - on refuse pourtant d'ouvrir une échelle générique de priorités items.
     BattleActionBagHpHealItemUse() => 7,
diff --git a/packages/map_battle/test/battle_session_test.dart b/packages/map_battle/test/battle_session_test.dart
index 04e1017e..07541e28 100644
--- a/packages/map_battle/test/battle_session_test.dart
+++ b/packages/map_battle/test/battle_session_test.dart
@@ -1151,5 +1151,76 @@ void main() {
         isA<BattleTurnBagHpHealItemEvent>(),
       );
     });
+
+    test(
+        'applyHyperPotionTurn commits a real turn and records a hyper potion timeline event',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 260,
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
+      final updatedSession = session.applyHyperPotionTurn(
+        targetLineupIndex: 0,
+        healAmount: 200,
+      );
+
+      expect(updatedSession.state.currentTurn, isNotNull);
+      expect(updatedSession.state.player.currentHp, equals(212));
+      expect(
+        updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.hyperPotion),
+        ),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents,
+        hasLength(1),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.hyperPotion),
+      );
+      expect(
+        updatedSession.state.currentTurn!.timeline.first,
+        isA<BattleTurnBagHpHealItemEvent>(),
+      );
+      expect(
+        updatedSession.state.currentTurn!.timeline.last,
+        isA<BattleTurnExecutionEvent>(),
+      );
+    });
   });
 }
diff --git a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart b/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
deleted file mode 100644
index f8084111..00000000
--- a/packages/map_runtime/lib/src/application/runtime_battle_potion_apply.dart
+++ /dev/null
@@ -1,249 +0,0 @@
-import 'package:map_battle/map_battle.dart';
-import 'package:map_core/map_core.dart';
-
-import 'runtime_battle_outcome_apply.dart';
-
-const _runtimeBattleMedicineCategoryId = 'medicine';
-const _runtimeBattlePotionHealAmount = 20;
-const _runtimeBattleSuperPotionHealAmount = 50;
-
-class RuntimeBattleBagHpHealItemApplyResult {
-  const RuntimeBattleBagHpHealItemApplyResult({
-    required this.updatedSession,
-    required this.updatedGameState,
-    required this.itemKind,
-    required this.targetSpeciesId,
-    required this.targetLineupIndex,
-    required this.healedAmount,
-  });
-
-  final BattleSession updatedSession;
-  final GameState updatedGameState;
-  final BattleBagHpHealItemKind itemKind;
-  final String targetSpeciesId;
-  final int targetLineupIndex;
-  final int healedAmount;
-}
-
-/// Lot 9-f garde le fichier historique pour minimiser le blast radius, mais le
-/// seam réel n'est plus "Potion seulement" :
-/// - on supporte exactement `Potion` + `Super Potion` ;
-/// - on refuse tout autre item ;
-/// - le moteur battle commit le vrai tour ;
-/// - le runtime reste propriétaire du bag réel et du write-back party.
-RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattlePotionUse({
-  required BattleSession session,
-  required GameState gameState,
-  required RuntimeActiveBattleContext context,
-  required int targetLineupIndex,
-}) {
-  return _tryApplyRuntimeBattleBagHpHealItemUse(
-    session: session,
-    gameState: gameState,
-    context: context,
-    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.potion),
-    targetLineupIndex: targetLineupIndex,
-  );
-}
-
-/// Support explicite ajouté par le lot 9-f.
-///
-/// On garde une façade par objet pour ne pas vendre une API runtime "tous
-/// items", même si l'implémentation partage le cœur avec `Potion`.
-RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleSuperPotionUse({
-  required BattleSession session,
-  required GameState gameState,
-  required RuntimeActiveBattleContext context,
-  required int targetLineupIndex,
-}) {
-  return _tryApplyRuntimeBattleBagHpHealItemUse(
-    session: session,
-    gameState: gameState,
-    context: context,
-    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.superPotion),
-    targetLineupIndex: targetLineupIndex,
-  );
-}
-
-RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
-  required BattleSession session,
-  required GameState gameState,
-  required RuntimeActiveBattleContext context,
-  required _RuntimeBattleBagHpHealItemSpec itemSpec,
-  required int targetLineupIndex,
-}) {
-  if (session.decisionRequest is! BattleTurnChoiceRequest) {
-    return null;
-  }
-
-  final targetCombatant = _findPlayerCombatantByLineupIndex(
-    session: session,
-    targetLineupIndex: targetLineupIndex,
-  );
-  if (targetCombatant == null ||
-      targetCombatant.isFainted ||
-      targetCombatant.currentHp >= targetCombatant.maxHp) {
-    return null;
-  }
-
-  if (!_hasBagHpHealItemAvailable(
-    bag: gameState.bag,
-    itemSpec: itemSpec,
-  )) {
-    return null;
-  }
-
-  final healedCombatant = targetCombatant.withHeal(itemSpec.healAmount);
-  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
-  if (healedAmount <= 0) {
-    return null;
-  }
-
-  final updatedSession = switch (itemSpec.kind) {
-    BattleBagHpHealItemKind.potion => session.applyPotionTurn(
-        targetLineupIndex: targetLineupIndex,
-        healAmount: itemSpec.healAmount,
-      ),
-    BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
-        targetLineupIndex: targetLineupIndex,
-        healAmount: itemSpec.healAmount,
-      ),
-  };
-  final updatedGameState = _applyCommittedBagHpHealItemTurnToRuntimeState(
-    gameState: gameState,
-    context: context,
-    updatedSession: updatedSession,
-    itemSpec: itemSpec,
-  );
-
-  return RuntimeBattleBagHpHealItemApplyResult(
-    updatedSession: updatedSession,
-    updatedGameState: updatedGameState,
-    itemKind: itemSpec.kind,
-    targetSpeciesId: healedCombatant.speciesId,
-    targetLineupIndex: healedCombatant.lineupIndex,
-    healedAmount: healedAmount,
-  );
-}
-
-BattleCombatant? _findPlayerCombatantByLineupIndex({
-  required BattleSession session,
-  required int targetLineupIndex,
-}) {
-  final active = session.state.player;
-  if (active.lineupIndex == targetLineupIndex) {
-    return active;
-  }
-  for (final combatant in session.state.playerReserve) {
-    if (combatant.lineupIndex == targetLineupIndex) {
-      return combatant;
-    }
-  }
-  return null;
-}
-
-// Lot 9-f reste runtime-owner pour la vérité hors moteur :
-// - write-back réel de toute la lineup engagée ;
-// - consommation réelle du bon item de bag ;
-// - aucune divergence overlay-only.
-GameState _applyCommittedBagHpHealItemTurnToRuntimeState({
-  required GameState gameState,
-  required RuntimeActiveBattleContext context,
-  required BattleSession updatedSession,
-  required _RuntimeBattleBagHpHealItemSpec itemSpec,
-}) {
-  final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
-    gameState: gameState,
-    context: context,
-    battleState: updatedSession.state,
-  );
-  return withCommittedHp.copyWith(
-    bag: _consumeOneBagHpHealItemOrThrow(
-      bag: withCommittedHp.bag,
-      itemSpec: itemSpec,
-    ),
-  );
-}
-
-bool _hasBagHpHealItemAvailable({
-  required Bag bag,
-  required _RuntimeBattleBagHpHealItemSpec itemSpec,
-}) {
-  for (final entry in bag.normalized().entries) {
-    if (entry.itemId == itemSpec.itemId &&
-        entry.categoryId == _runtimeBattleMedicineCategoryId) {
-      return true;
-    }
-  }
-  return false;
-}
-
-Bag _consumeOneBagHpHealItemOrThrow({
-  required Bag bag,
-  required _RuntimeBattleBagHpHealItemSpec itemSpec,
-}) {
-  final nextEntries = <BagEntry>[];
-  var consumed = false;
-
-  for (final entry in bag.normalized().entries) {
-    final isRequestedItem = entry.itemId == itemSpec.itemId &&
-        entry.categoryId == _runtimeBattleMedicineCategoryId;
-    if (!isRequestedItem) {
-      nextEntries.add(entry);
-      continue;
-    }
-    if (consumed) {
-      nextEntries.add(entry);
-      continue;
-    }
-
-    consumed = true;
-    final nextQuantity = entry.quantity - 1;
-    if (nextQuantity > 0) {
-      nextEntries.add(entry.copyWith(quantity: nextQuantity));
-    }
-  }
-
-  if (!consumed) {
-    throw StateError(
-      'Impossible de consommer ${itemSpec.label} : aucune entrée '
-      '${itemSpec.itemId} disponible.',
-    );
-  }
-
-  return Bag(entries: nextEntries).normalized();
-}
-
-_RuntimeBattleBagHpHealItemSpec _runtimeItemSpec(
-  BattleBagHpHealItemKind kind,
-) {
-  return switch (kind) {
-    BattleBagHpHealItemKind.potion => const _RuntimeBattleBagHpHealItemSpec(
-        kind: BattleBagHpHealItemKind.potion,
-        itemId: 'potion',
-        label: 'Potion',
-        healAmount: _runtimeBattlePotionHealAmount,
-      ),
-    BattleBagHpHealItemKind.superPotion =>
-      const _RuntimeBattleBagHpHealItemSpec(
-        kind: BattleBagHpHealItemKind.superPotion,
-        itemId: 'super-potion',
-        label: 'Super Potion',
-        healAmount: _runtimeBattleSuperPotionHealAmount,
-      ),
-  };
-}
-
-class _RuntimeBattleBagHpHealItemSpec {
-  const _RuntimeBattleBagHpHealItemSpec({
-    required this.kind,
-    required this.itemId,
-    required this.label,
-    required this.healAmount,
-  });
-
-  final BattleBagHpHealItemKind kind;
-  final String itemId;
-  final String label;
-  final int healAmount;
-}
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
index 65a81ee3..ae699bfc 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
@@ -234,15 +234,18 @@ BattleBagItemKind _classifyBagItem(BagEntry bagEntry) {
 }
 
 bool _isSupportedMedicine(BagEntry bagEntry) {
-  // Lot 9-f factorise ici le strict minimum utile :
+  // Lot 9-g factorise ici le strict minimum utile :
   // - `potion`
   // - `super-potion`
+  // - `hyper-potion`
   //
   // On ne bascule pas vers un registre d'items ni vers un catalogue runtime.
   if (bagEntry.categoryId != 'medicine') {
     return false;
   }
-  return bagEntry.itemId == 'potion' || bagEntry.itemId == 'super-potion';
+  return bagEntry.itemId == 'potion' ||
+      bagEntry.itemId == 'super-potion' ||
+      bagEntry.itemId == 'hyper-potion';
 }
 
 BattleBagMenuDisabledReason _captureDisabledReason({
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
index e28852ff..28c60258 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
@@ -330,6 +330,7 @@ String? _overlaySupportedMedicineLabel(String itemId) {
   return switch (itemId) {
     'potion' => 'Potion',
     'super-potion' => 'Super Potion',
+    'hyper-potion' => 'Hyper Potion',
     _ => null,
   };
 }
@@ -1109,8 +1110,10 @@ class BattleOverlayComponent extends PositionComponent {
       return false;
     }
 
-    // Lots 9-e / 9-f gardent l'overlay strictement borné au shell de ciblage :
-    // - le parent runtime commit le vrai tour pour `Potion` / `Super Potion` ;
+    // Lots 9-e / 9-f / 9-g gardent l'overlay strictement borné au shell de
+    // ciblage :
+    // - le parent runtime commit le vrai tour pour `Potion`, `Super Potion`
+    //   et `Hyper Potion` ;
     // - l'overlay ne patche plus sa session localement ;
     // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
     //   propriétaire unique du vrai BattleSession / GameState.
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 2b6ea93f..5a2fcf36 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -35,7 +35,7 @@ import '../../application/placed_behavior_runtime_cooldown.dart';
 import '../../application/resolve_dialogue.dart';
 import '../../application/runtime_battle_setup_mapper.dart';
 import '../../application/runtime_battle_outcome_apply.dart';
-import '../../application/runtime_battle_potion_apply.dart';
+import '../../application/runtime_battle_bag_hp_heal_item_apply.dart';
 import '../../application/runtime_battle_combatant_seed_builder.dart';
 import '../../application/runtime_character_refs.dart';
 import '../../application/runtime_map_bundle.dart';
@@ -3990,11 +3990,12 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
 
     _isBattleResolving = true;
     try {
-      // Lots 9-e / 9-f gardent `PlayableMapGame` comme propriétaire honnête
+      // Lots 9-e / 9-f / 9-g gardent `PlayableMapGame` comme propriétaire honnête
       // du runtime autour du moteur battle :
       // - le moteur battle produit un `currentTurn` et une timeline honnêtes ;
       // - le runtime reste propriétaire du bag réel et du write-back party ;
-      // - on reste borné à `Potion` + `Super Potion`, sans API item générique.
+      // - on reste borné à `Potion` + `Super Potion` + `Hyper Potion`,
+      //   sans API item générique.
       final result = switch (action.itemId) {
         'potion' => tryApplyRuntimeBattlePotionUse(
             session: battleSession,
@@ -4008,6 +4009,12 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
             context: activeBattleContext,
             targetLineupIndex: entry.lineupIndex,
           ),
+        'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
+            session: battleSession,
+            gameState: _gameState,
+            context: activeBattleContext,
+            targetLineupIndex: entry.lineupIndex,
+          ),
         _ => null,
       };
       if (result == null) {
diff --git a/packages/map_runtime/test/battle_bag_menu_model_test.dart b/packages/map_runtime/test/battle_bag_menu_model_test.dart
index 451f4a3d..331edfbb 100644
--- a/packages/map_runtime/test/battle_bag_menu_model_test.dart
+++ b/packages/map_runtime/test/battle_bag_menu_model_test.dart
@@ -449,6 +449,60 @@ void main() {
       );
     });
 
+    test(
+        'supported hyper potion is selectable in a free turn and opens a medicine target action',
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
+                itemId: 'hyper-potion',
+                categoryId: 'medicine',
+                quantity: 1,
+              ),
+            ],
+          ),
+        ),
+        session: session,
+      );
+
+      final entry = model.entries.single;
+      expect(entry.kind, equals(BattleBagItemKind.medicine));
+      expect(entry.quantity, equals(1));
+      expect(entry.isSelectable, isTrue);
+      expect(entry.disabledReason, isNull);
+      expect(
+        entry.action,
+        isA<BattleBagMenuActionMedicineTarget>()
+            .having(
+              (action) => action.itemId,
+              'itemId',
+              equals('hyper-potion'),
+            )
+            .having(
+              (action) => action.categoryId,
+              'categoryId',
+              equals('medicine'),
+            )
+            .having((action) => action.quantity, 'quantity', equals(1)),
+      );
+    });
+
     test('unsupported medicine stays visible but disabled', () {
       final session = _session(
         player: _combatant(
diff --git a/packages/map_runtime/test/battle_overlay_component_test.dart b/packages/map_runtime/test/battle_overlay_component_test.dart
index ecce6894..93c35ec7 100644
--- a/packages/map_runtime/test/battle_overlay_component_test.dart
+++ b/packages/map_runtime/test/battle_overlay_component_test.dart
@@ -9,7 +9,7 @@ import 'package:map_core/map_core.dart';
 import 'package:map_gameplay/src/direction.dart';
 import 'package:map_runtime/src/application/battle_start_request.dart';
 import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
-import 'package:map_runtime/src/application/runtime_battle_potion_apply.dart';
+import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
 import 'package:map_runtime/src/application/runtime_map_bundle.dart';
 import 'package:map_runtime/src/presentation/flame/battle_background_resolver.dart';
 import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';
@@ -1379,6 +1379,28 @@ void main() {
                 ),
                 targetLineupIndex: entry.lineupIndex,
               ),
+            'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
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
             _ => null,
           };
           if (result == null) {
@@ -1515,6 +1537,28 @@ void main() {
                 ),
                 targetLineupIndex: entry.lineupIndex,
               ),
+            'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
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
             _ => null,
           };
           if (result == null) {
@@ -1645,6 +1689,28 @@ void main() {
                 ),
                 targetLineupIndex: entry.lineupIndex,
               ),
+            'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
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
             _ => null,
           };
           if (result == null) {
@@ -1694,6 +1760,164 @@ void main() {
       expect(overlay.currentPromptText, equals('sproutle récupère 50 PV.'));
     });
 
+    test(
+        'selecting a valid hyper potion target commits a real turn without dispatching a PlayerBattleChoice',
+        () async {
+      PlayerBattleChoice? pickedChoice;
+      final session = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 22,
+          maxHp: 260,
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
+              itemId: 'hyper-potion',
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
+            'hyper-potion' => tryApplyRuntimeBattleHyperPotionUse(
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
+          equals(BattleBagHpHealItemKind.hyperPotion),
+        ),
+      );
+      expect(overlay.debugSession.state.player.currentHp, equals(222));
+      expect(
+        overlay.debugGameState.party.members.first.currentHp,
+        equals(222),
+      );
+      expect(overlay.debugGameState.bag.entries, isEmpty);
+      expect(overlay.isTurnPresentationActive, isTrue);
+      expect(
+        overlay.currentPromptText,
+        equals('Joueur utilise Hyper Potion sur sproutle !'),
+      );
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+      expect(overlay.validateSelectedChoice(), isFalse);
+
+      overlay.updateTree(0.50);
+      expect(overlay.currentPromptText, equals('sproutle récupère 200 PV.'));
+    });
+
     test('full hp medicine targets stay visible but non-selectable', () async {
       final overlay = BattleOverlayComponent(
         session: _session(
diff --git a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
index c71dd515..a4f0b385 100644
--- a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
+++ b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
@@ -4,7 +4,7 @@ import 'package:map_core/map_core.dart';
 import 'package:map_gameplay/map_gameplay.dart';
 import 'package:map_runtime/src/application/battle_start_request.dart';
 import 'package:map_runtime/src/application/runtime_battle_outcome_apply.dart';
-import 'package:map_runtime/src/application/runtime_battle_potion_apply.dart';
+import 'package:map_runtime/src/application/runtime_battle_bag_hp_heal_item_apply.dart';
 
 BattleStatsSnapshot _stats() {
   return const BattleStatsSnapshot(
@@ -120,7 +120,7 @@ RuntimeActiveBattleContext _context({
 }
 
 void main() {
-  group('tryApplyRuntimeBattlePotionUse', () {
+  group('tryApplyRuntimeBattleBagHpHealItemUse', () {
     test('potion heals a damaged active target by 20 and consumes one item',
         () {
       final result = tryApplyRuntimeBattlePotionUse(
@@ -325,6 +325,129 @@ void main() {
       expect(result.updatedGameState.bag.entries, isEmpty);
     });
 
+    test(
+        'hyper potion heals a damaged active target by 200 and consumes only hyper potion',
+        () {
+      final result = tryApplyRuntimeBattleHyperPotionUse(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 12,
+            maxHp: 260,
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
+              BagEntry(
+                itemId: 'hyper-potion',
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
+      expect(result!.healedAmount, equals(200));
+      expect(
+        result.updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>().having(
+          (action) => action.itemKind,
+          'itemKind',
+          equals(BattleBagHpHealItemKind.hyperPotion),
+        ),
+      );
+      expect(result.updatedSession.state.player.currentHp, equals(212));
+      expect(
+          result.updatedGameState.party.members.first.currentHp, equals(212));
+      expect(
+        result.updatedGameState.bag.entries,
+        const Bag(
+          entries: <BagEntry>[
+            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
+            BagEntry(
+              itemId: 'super-potion',
+              categoryId: 'medicine',
+              quantity: 2,
+            ),
+            BagEntry(
+              itemId: 'hyper-potion',
+              categoryId: 'medicine',
+              quantity: 1,
+            ),
+          ],
+        ).normalized().entries,
+      );
+    });
+
+    test('hyper potion heal is capped at max hp', () {
+      final result = tryApplyRuntimeBattleHyperPotionUse(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 190,
+            maxHp: 260,
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
+                itemId: 'hyper-potion',
+                categoryId: 'medicine',
+                quantity: 1,
+              ),
+            ],
+          ),
+          partyMembers: <PlayerPokemon>[
+            _partyMember(speciesId: 'sproutle', currentHp: 190),
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
+      expect(result!.healedAmount, equals(70));
+      expect(result.updatedSession.state.player.currentHp, equals(260));
+      expect(
+          result.updatedGameState.party.members.first.currentHp, equals(260));
+      expect(result.updatedGameState.bag.entries, isEmpty);
+    });
+
     test(
         'potion use removes the bag entry when quantity reaches zero and targets the intended reserve by lineup identity',
         () {
diff --git a/packages/map_runtime/test/battle_turn_presentation_test.dart b/packages/map_runtime/test/battle_turn_presentation_test.dart
index 8ab88b17..6b0fcdc2 100644
--- a/packages/map_runtime/test/battle_turn_presentation_test.dart
+++ b/packages/map_runtime/test/battle_turn_presentation_test.dart
@@ -468,6 +468,112 @@ void main() {
       expect(steps[2].hpTo, equals(53));
     });
 
+    test(
+        'renders hyper potion use as a committed turn step before the enemy response',
+        () {
+      final beforeSession = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          maxHp: 260,
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
+          itemKind: BattleBagHpHealItemKind.hyperPotion,
+          targetLineupIndex: 0,
+          healAmount: 200,
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
+            itemKind: BattleBagHpHealItemKind.hyperPotion,
+            side: BattleSideId.player,
+            targetLineupIndex: 0,
+            targetSpeciesId: 'sproutle',
+            hpBefore: 12,
+            hpAfter: 212,
+          ),
+        ],
+        timeline: <BattleTurnEvent>[
+          BattleTurnBagHpHealItemEvent(
+            BattleBagHpHealItemEvent(
+              itemKind: BattleBagHpHealItemKind.hyperPotion,
+              side: BattleSideId.player,
+              targetLineupIndex: 0,
+              targetSpeciesId: 'sproutle',
+              hpBefore: 12,
+              hpAfter: 212,
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
+        equals('Joueur utilise Hyper Potion sur sproutle !'),
+      );
+      expect(steps[1].message, equals('sproutle récupère 200 PV.'));
+      expect(steps[1].hpFrom, equals(12));
+      expect(steps[1].hpTo, equals(212));
+      expect(steps[2].hpFrom, equals(212));
+      expect(steps[2].hpTo, equals(203));
+    });
+
     test('keeps status-like executions as message-only steps', () {
       final beforeSession = _session(
         player: _combatant(
diff --git a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
index a4134a02..a64c574e 100644
--- a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
+++ b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
@@ -742,6 +742,121 @@ void main() {
       );
       expect(game.gameStateSnapshot.bag.entries, isEmpty);
     });
+
+    test('battle BAG hyper potion use persists to PlayableMapGame state',
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
+        saveId: 'wild-flow-hyper-potion-save',
+        bag: Bag(
+          entries: <BagEntry>[
+            BagEntry(
+              itemId: 'hyper-potion',
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
+      final expectedHealedHp = min(initialBattleHp + 200, initialBattleMaxHp);
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
+          equals(BattleBagHpHealItemKind.hyperPotion),
+        ),
+      );
+      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
+      expect(
+        currentTurn.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.hyperPotion),
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
   });
 }
 
```

## Appendice B — contenu complet (patch d'ajout) du nouveau fichier créé par le lot

```diff
--- /dev/null	2026-04-22 19:42:26
+++ /Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart	2026-04-22 19:38:24
@@ -0,0 +1,286 @@
+import 'package:map_battle/map_battle.dart';
+import 'package:map_core/map_core.dart';
+
+import 'runtime_battle_outcome_apply.dart';
+
+const _runtimeBattleMedicineCategoryId = 'medicine';
+const _runtimeBattlePotionHealAmount = 20;
+const _runtimeBattleSuperPotionHealAmount = 50;
+const _runtimeBattleHyperPotionHealAmount = 200;
+
+class RuntimeBattleBagHpHealItemApplyResult {
+  const RuntimeBattleBagHpHealItemApplyResult({
+    required this.updatedSession,
+    required this.updatedGameState,
+    required this.itemKind,
+    required this.targetSpeciesId,
+    required this.targetLineupIndex,
+    required this.healedAmount,
+  });
+
+  final BattleSession updatedSession;
+  final GameState updatedGameState;
+  final BattleBagHpHealItemKind itemKind;
+  final String targetSpeciesId;
+  final int targetLineupIndex;
+  final int healedAmount;
+}
+
+/// Runtime owner du mini-slice BAG HP-heal battle.
+///
+/// Le renommage devient utile au lot 9-g :
+/// - avec `Potion` + `Super Potion` + `Hyper Potion`, le nom historique
+///   `runtime_battle_potion_apply.dart` devient trop mensonger ;
+/// - le blast radius reste raisonnable car ce seam n'est importé qu'en
+///   interne par le runtime et ses tests ;
+/// - on reste malgré tout strictement borné à trois objets, pas à une famille
+///   ouverte de medicines.
+RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattlePotionUse({
+  required BattleSession session,
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required int targetLineupIndex,
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
+/// Support explicite ajouté par le lot 9-g.
+///
+/// Le runtime expose toujours une façade par objet pour éviter toute ambiguïté
+/// produit :
+/// - pas de registre d'items ;
+/// - pas de `itemId` arbitraire côté API publique ;
+/// - seulement le troisième objet explicitement demandé.
+RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleHyperPotionUse({
+  required BattleSession session,
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required int targetLineupIndex,
+}) {
+  return _tryApplyRuntimeBattleBagHpHealItemUse(
+    session: session,
+    gameState: gameState,
+    context: context,
+    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.hyperPotion),
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
+}) {
+  if (session.decisionRequest is! BattleTurnChoiceRequest) {
+    return null;
+  }
+
+  final targetCombatant = _findPlayerCombatantByLineupIndex(
+    session: session,
+    targetLineupIndex: targetLineupIndex,
+  );
+  if (targetCombatant == null ||
+      targetCombatant.isFainted ||
+      targetCombatant.currentHp >= targetCombatant.maxHp) {
+    return null;
+  }
+
+  if (!_hasBagHpHealItemAvailable(
+    bag: gameState.bag,
+    itemSpec: itemSpec,
+  )) {
+    return null;
+  }
+
+  final healedCombatant = targetCombatant.withHeal(itemSpec.healAmount);
+  final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
+  if (healedAmount <= 0) {
+    return null;
+  }
+
+  final updatedSession = switch (itemSpec.kind) {
+    BattleBagHpHealItemKind.potion => session.applyPotionTurn(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: itemSpec.healAmount,
+      ),
+    BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: itemSpec.healAmount,
+      ),
+    BattleBagHpHealItemKind.hyperPotion => session.applyHyperPotionTurn(
+        targetLineupIndex: targetLineupIndex,
+        healAmount: itemSpec.healAmount,
+      ),
+  };
+  final updatedGameState = _applyCommittedBagHpHealItemTurnToRuntimeState(
+    gameState: gameState,
+    context: context,
+    updatedSession: updatedSession,
+    itemSpec: itemSpec,
+  );
+
+  return RuntimeBattleBagHpHealItemApplyResult(
+    updatedSession: updatedSession,
+    updatedGameState: updatedGameState,
+    itemKind: itemSpec.kind,
+    targetSpeciesId: healedCombatant.speciesId,
+    targetLineupIndex: healedCombatant.lineupIndex,
+    healedAmount: healedAmount,
+  );
+}
+
+BattleCombatant? _findPlayerCombatantByLineupIndex({
+  required BattleSession session,
+  required int targetLineupIndex,
+}) {
+  final active = session.state.player;
+  if (active.lineupIndex == targetLineupIndex) {
+    return active;
+  }
+  for (final combatant in session.state.playerReserve) {
+    if (combatant.lineupIndex == targetLineupIndex) {
+      return combatant;
+    }
+  }
+  return null;
+}
+
+// Le fil 9-d -> 9-g garde le runtime propriétaire de la vérité hors moteur :
+// - write-back réel de toute la lineup engagée ;
+// - consommation réelle du bon item de bag ;
+// - aucune divergence overlay-only.
+GameState _applyCommittedBagHpHealItemTurnToRuntimeState({
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required BattleSession updatedSession,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+}) {
+  final withCommittedHp = writePlayerBattleLineupBackToPartySlots(
+    gameState: gameState,
+    context: context,
+    battleState: updatedSession.state,
+  );
+  return withCommittedHp.copyWith(
+    bag: _consumeOneBagHpHealItemOrThrow(
+      bag: withCommittedHp.bag,
+      itemSpec: itemSpec,
+    ),
+  );
+}
+
+bool _hasBagHpHealItemAvailable({
+  required Bag bag,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+}) {
+  for (final entry in bag.normalized().entries) {
+    if (entry.itemId == itemSpec.itemId &&
+        entry.categoryId == _runtimeBattleMedicineCategoryId) {
+      return true;
+    }
+  }
+  return false;
+}
+
+Bag _consumeOneBagHpHealItemOrThrow({
+  required Bag bag,
+  required _RuntimeBattleBagHpHealItemSpec itemSpec,
+}) {
+  final nextEntries = <BagEntry>[];
+  var consumed = false;
+
+  for (final entry in bag.normalized().entries) {
+    final isRequestedItem = entry.itemId == itemSpec.itemId &&
+        entry.categoryId == _runtimeBattleMedicineCategoryId;
+    if (!isRequestedItem) {
+      nextEntries.add(entry);
+      continue;
+    }
+    if (consumed) {
+      nextEntries.add(entry);
+      continue;
+    }
+
+    consumed = true;
+    final nextQuantity = entry.quantity - 1;
+    if (nextQuantity > 0) {
+      nextEntries.add(entry.copyWith(quantity: nextQuantity));
+    }
+  }
+
+  if (!consumed) {
+    throw StateError(
+      'Impossible de consommer ${itemSpec.label} : aucune entrée '
+      '${itemSpec.itemId} disponible.',
+    );
+  }
+
+  return Bag(entries: nextEntries).normalized();
+}
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
+    BattleBagHpHealItemKind.hyperPotion =>
+      const _RuntimeBattleBagHpHealItemSpec(
+        kind: BattleBagHpHealItemKind.hyperPotion,
+        itemId: 'hyper-potion',
+        label: 'Hyper Potion',
+        healAmount: _runtimeBattleHyperPotionHealAmount,
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
```

## Appendice C — note sur le report lui-même
Ce report est lui-même un fichier créé par le lot. Il n'est pas récursivement diffé contre lui-même : son contenu actuel complet constitue la représentation exhaustive demandée pour ce fichier.
