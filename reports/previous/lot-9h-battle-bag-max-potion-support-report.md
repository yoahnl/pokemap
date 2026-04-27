# Lot 9-h — Battle BAG max potion support

## Résumé exécutif
Le lot 9-h ajoute `max-potion` au fil BAG battle existant `Potion` + `Super Potion` + `Hyper Potion` sans ouvrir de système générique d'items. `Max Potion` est sélectionnable dans le BAG battle, réutilise le shell medicine, cible uniquement les Pokémon vivants non full HP de la lineup, commit un vrai tour, produit une timeline, restaure à `maxHp`, écrit les PV dans `GameState.party`, et consomme exactement une entrée `max-potion`.

Décision d'architecture : extension strictement bornée de la mini-famille HP heal avec un micro-modèle d'effet `BattleBagHpHealEffect`. Les trois premiers objets restent des soins plats, `Max Potion` utilise `BattleBagRestoreToFullHpHealEffect`. Le modèle à base de `healAmount` seul n'était pas honnête pour `Max Potion`.

## Confirmation du scope
- Inclus : `max-potion` seulement dans le flow battle BAG runtime/UI/runtime/battle.
- Conservé : `potion`, `super-potion`, `hyper-potion`, capture BAG 9-b.
- Exclu : BDC-01, bridge runtime -> battle des moves, Bubble/Bubble Beam, converter Showdown, overworld items, held items, key items, catalogues/API 2175 objets, registre générique d'items battle.

## Critique du prompt
- Point correct : le prompt insiste sur le fait que `Max Potion` n'est pas un `healAmount` plat. L'audit repo confirme que l'ancien seam `healAmount` seul aurait été mensonger.
- Point discutable : l'exigence "maximum de commentaires" peut pousser à du bruit. J'ai ajouté des commentaires utiles sur les frontières de lot et les invariants, sans commenter les évidences.
- Point lourd : l'exigence d'inclure le contenu complet/diff de tous les fichiers dans le rapport est coûteuse et peut rendre le rapport peu lisible. Alternative plus légère proposée pour les prochains lots : rapport synthétique + diff attaché généré. Pour ce lot, le diff unifié exhaustif des fichiers code/test touchés est inclus en annexe.
- Ambiguïté mineure : inclure le contenu complet du rapport dans lui-même serait récursif. Interprétation retenue : le rapport est lui-même le contenu complet du fichier créé, et l'annexe contient le diff exhaustif de tous les fichiers code/test modifiés par le lot.

## Audit initial
### Fichiers concernés
- `packages/map_battle/lib/src/battle_action.dart` : action BAG HP heal et enum d'items.
- `packages/map_battle/lib/src/battle_session.dart` : façades `applyPotionTurn`, `applySuperPotionTurn`, `applyHyperPotionTurn`, validation cible et résolution.
- `packages/map_battle/lib/src/battle_session_scheduler.dart` : exécution de `BattleActionBagHpHealItemUse` dans la queue de tour.
- `packages/map_battle/lib/src/battle_resolution.dart` : événement déjà suffisant avec `hpBefore/hpAfter` et `healedAmount` dérivé.
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart` : seam runtime propriétaire du bag et du write-back party.
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart` : whitelist medicine supportée.
- `packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart` : shell cible item-agnostique déjà compatible.
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` : label medicine et dispatch vers parent runtime.
- `packages/map_runtime/lib/src/presentation/flame/battle_turn_presentation.dart` : narration déjà basée sur `itemKind.label` et `healedAmount`.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` : propriétaire runtime de session/GameState/bag.

### Contrats existants
- Avant 9-h, `BattleBagHpHealItemKind` couvrait seulement `potion`, `superPotion`, `hyperPotion`.
- `BattleActionBagHpHealItemUse` portait un `healAmount` plat strictement positif.
- Le runtime exposait une façade par objet (`tryApplyRuntimeBattlePotionUse`, `tryApplyRuntimeBattleSuperPotionUse`, `tryApplyRuntimeBattleHyperPotionUse`).
- Les targets medicine étaient déjà vivantes, non full HP, et basées sur `lineupIndex`.
- La timeline battle possédait déjà `BattleBagHpHealItemEvent(hpBefore, hpAfter)` ; aucun changement de contrat de présentation n'était nécessaire.

### Tests existants pertinents
- `packages/map_battle/test/battle_session_test.dart` : vrais tours Potion/Super/Hyper.
- `packages/map_runtime/test/battle_bag_menu_model_test.dart` : support BAG et disabled entries.
- `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart` : cibles vivantes/non full/fainted.
- `packages/map_runtime/test/battle_overlay_component_test.dart` : flow overlay medicine.
- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart` : apply runtime Potion/Super/Hyper.
- `packages/map_runtime/test/battle_turn_presentation_test.dart` : narration Potion/Super/Hyper.
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart` : synchronisation `PlayableMapGame`.

### Rapports relus / pris en compte
Les rapports 9-a à 9-g décrivent le fil BAG battle progressif. Le rapport 9-g confirme la mini-factorisation bornée Potion/Super/Hyper et l'absence de registre générique. Le rapport BDC-01 a été relu comme risque de confusion de chantier ; il est hors scope et n'a pas été prolongé.

### Risques principaux
- Représenter `Max Potion` avec un faux montant plat (`999`, `maxHp`, ou missing HP comme propriété intrinsèque) aurait menti au moteur.
- Un `itemId` libre dans `map_battle` aurait ouvert un framework générique hors scope.
- Oublier le write-back `GameState.party` ou la consommation exacte du bag aurait créé une divergence overlay/runtime.
- Ne pas garder les garde-fous en runtime release aurait permis des soins plats négatifs ou nuls.

## Décision d'architecture
Choix retenu : extension bornée de la mini-famille actuelle avec un micro-modèle d'effet.

- Option A pure (`healAmount` pour tout) rejetée : elle tord le contrat car `Max Potion` restaure à `maxHp` et non un montant plat.
- Option B (micro-seam distinct totalement séparé) non retenue : elle dupliquerait le ciblage, la queue de tour, la timeline et le write-back alors que seule la sémantique de soin change.
- Option C retenue : garder la famille fermée `BattleBagHpHealItemKind` à quatre objets, ajouter `BattleBagFlatHpHealEffect` et `BattleBagRestoreToFullHpHealEffect`, et conserver des façades explicites par objet.

Pourquoi c'est le plus petit seam honnête : le moteur continue à ne connaître que quatre objets fermés, le runtime continue à exposer une façade par item, et la différence `flat` vs `restore-to-full` est représentée par un type minuscule plutôt que par une valeur magique.

## Sémantique Max Potion
Aucun canon local préexistant complet pour `max-potion` n'a été trouvé lors de l'audit initial. Sémantique retenue pour 9-h :
- restaure à `maxHp` ;
- `healedAmount = maxHp - currentHp` au moment de la résolution ;
- cible invalide si full HP ;
- cible invalide si K.O. ;
- écrit le résultat post-tour dans la party runtime.

Point potentiellement discutable selon les générations Pokémon : certaines générations ont des variations de disponibilité/prix/contexte, mais la sémantique de soin en combat retenue ici est volontairement limitée à "restore HP to full".

## État git initial
État observé au début du lot :

```text
 M AGENTS.md
```

`AGENTS.md` était déjà modifié avant le lot et n'a pas été intégré au scope.

## Fichiers modifiés / créés / supprimés
### Créé
- `reports/lot-9h-battle-bag-max-potion-support-report.md` : présent rapport.

### Modifiés par le lot
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_session_scheduler.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart`
- `packages/map_runtime/test/battle_turn_presentation_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

### Supprimés
- Aucun fichier supprimé.

### Hors scope déjà présent
- `AGENTS.md` reste modifié dans le worktree, mais était déjà sale au début et n'a pas été inclus dans le diff du lot.

## Détail par fichier touché
- `packages/map_battle/lib/src/battle_action.dart` : ajout `BattleBagHpHealItemKind.maxPotion`, ajout des effets `BattleBagHpHealEffect`, `BattleBagFlatHpHealEffect`, `BattleBagRestoreToFullHpHealEffect`, garde-fous assert sur les combinaisons item/effect. Impact : `Max Potion` n'est pas représentée comme un soin plat.
- `packages/map_battle/lib/src/battle_session.dart` : ajout `applyMaxPotionTurn`, résolution restore-to-full, validation runtime des couples item/effect, validation runtime des montants plats positifs. Impact : vrai tour battle et garde-fous release.
- `packages/map_battle/lib/src/battle_session_scheduler.dart` : passage de `resolvedEffect` à la résolution. Impact : la queue de tour exécute l'effet committé.
- `packages/map_battle/test/battle_session_test.dart` : tests Max Potion vrai tour, cibles invalides, garde-fous restore-to-full, montants plats non positifs. Impact : couverture moteur positive/négative/non-régression.
- `packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart` : ajout `tryApplyRuntimeBattleMaxPotionUse`, spec runtime à effet, consommation exacte `max-potion`, write-back existant réutilisé. Impact : runtime propriétaire honnête du bag et de la party.
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart` : whitelist `max-potion`. Impact : selectable seulement si medicine supportée dans un vrai `BattleTurnChoiceRequest`.
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart` : mapping icon local `max-potion`. Impact : entrée BAG visible avec icône cohérente sans catalogue générique.
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` : label `Max Potion` et commentaire de borne 9-h. Impact : shell cible et narration initiale corrects.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` : switch parent runtime vers `tryApplyRuntimeBattleMaxPotionUse`. Impact : `PlayableMapGame` reste propriétaire du vrai commit/session/GameState.
- `packages/map_runtime/test/battle_bag_menu_model_test.dart` : selectable Max Potion + display order/non-régressions Potion/Super/Hyper. Impact : BAG model couvert.
- `packages/map_runtime/test/battle_medicine_target_menu_model_test.dart` : metadata `max-potion` sur shell cible. Impact : cibles item-agnostiques prouvées.
- `packages/map_runtime/test/battle_overlay_component_test.dart` : flow overlay Max Potion vrai tour, narration, pas de second choix joueur. Impact : UX/runtime overlay couvert.
- `packages/map_runtime/test/battle_potion_apply_runtime_test.dart` : apply Max Potion restore max, quantité 1 supprimée, quantité >1 décrémentée, pas de consommation Potion/Super/Hyper, full/fainted invalides. Impact : runtime apply couvert.
- `packages/map_runtime/test/battle_turn_presentation_test.dart` : narration Max Potion avec PV réellement récupérés. Impact : timeline visible honnête.
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart` : synchronisation `PlayableMapGame` avec Max Potion. Impact : parent runtime/overlay/session/GameState cohérents.

## Tests créés ou modifiés
- Ajout de tests `Max Potion` dans `battle_session_test.dart`, `battle_bag_menu_model_test.dart`, `battle_medicine_target_menu_model_test.dart`, `battle_overlay_component_test.dart`, `battle_potion_apply_runtime_test.dart`, `battle_turn_presentation_test.dart`, `wild_battle_end_to_end_flow_test.dart`.
- Ajout de non-régressions explicites pour `Potion`, `Super Potion`, `Hyper Potion` dans BAG/runtime/turn flow.
- Ajout d'un garde-fou négatif pour montants plats non positifs.

## Commandes de test lancées
### Tests rouges TDD initiaux
- `cd packages/map_battle && /Users/karim/develop/flutter/bin/dart test test/battle_session_test.dart --name "MaxPotion"` : échec attendu avant implémentation (`maxPotion`, `applyMaxPotionTurn`, `BattleBagRestoreToFullHpHealEffect` absents).
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_bag_menu_model_test.dart --plain-name "supported max potion is selectable in a free turn and opens a medicine target action"` : échec attendu (`entry.isSelectable` false).
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_potion_apply_runtime_test.dart --plain-name "max potion heals a damaged active target to max hp and consumes only max potion"` : échec attendu (`tryApplyRuntimeBattleMaxPotionUse` absent).

### Tests ciblés finaux
- `cd packages/map_battle && /Users/karim/develop/flutter/bin/dart test test/battle_session_test.dart` : `+36`, all tests passed.
- `cd packages/map_battle && /Users/karim/develop/flutter/bin/dart test` : `+206`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_bag_menu_model_test.dart` : `+16`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_medicine_target_menu_model_test.dart` : `+6`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_overlay_component_test.dart` : `+51`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_potion_apply_runtime_test.dart` : `+11`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_turn_presentation_test.dart` : `+7`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/wild_battle_end_to_end_flow_test.dart` : `+12`, all tests passed.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test test/battle_potion_apply_runtime_test.dart test/wild_battle_end_to_end_flow_test.dart` : `+23`, all tests passed après correction finale du garde-fou battle.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test` : `+798`, all tests passed.
- `cd examples/playable_runtime_host && /Users/karim/develop/flutter/bin/flutter test test/phase_a_golden_slice_launch_test.dart` : `+1`, all tests passed.

### Échec de validation non lié au lot
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter test --no-pub test/battle_bag_menu_model_test.dart` : échec de chargement car `.dart_tool` pointait vers `/opt/homebrew/share/flutter` incompatible (`Required named parameter 'hitTestTransform' must be provided`). Relance sans `--no-pub` OK.

## Commandes d'analyse lancées
- `cd packages/map_battle && /Users/karim/develop/flutter/bin/dart analyze lib/src/battle_action.dart lib/src/battle_session.dart lib/src/battle_session_scheduler.dart lib/src/battle_resolution.dart test/battle_session_test.dart` : no issues found.
- `cd packages/map_battle && /Users/karim/develop/flutter/bin/dart analyze` : no issues found.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter analyze <14 fichiers runtime/test touchés>` : no issues found.
- `cd packages/map_runtime && /Users/karim/develop/flutter/bin/flutter analyze` : échec global existant, `325 issues found`, principalement `prefer_const_constructors`, imports relatifs dans tests, `invalid_dependency` path dependencies et warnings hors fichiers touchés. Non lié au lot.

## Commandes de build / validation downstream
- `cd examples/playable_runtime_host && /Users/karim/develop/flutter/bin/flutter build macos --debug` : succès, `Built build/macos/Build/Products/Debug/playable_runtime_host.app`.
- `cd examples/playable_runtime_host && /Users/karim/develop/flutter/bin/flutter build macos --debug --no-pub` après correction finale : succès, `Built build/macos/Build/Products/Debug/playable_runtime_host.app`.

Le host downstream a été considéré pertinent car il dépend directement de `map_runtime` et consomme le seam runtime/overlay.

## Sub-agents / passes séparées
- Sub-agent Audit / Architecture : OK. Verdict initial : le seam `healAmount` seul n'était pas honnête ; recommandation adoptée via micro-effet borné.
- Sub-agent Tests : OK. Verdict initial : couverture manquante ; tests ajoutés et passés.
- Sub-agent Implémentation : OK. A implémenté le gros du support ; corrections parent ajoutées pour resserrer les garde-fous.
- Sub-agent Build / Validation : OK pour le lot. Tests/build ciblés et full tests passent ; analyse complète runtime reste en dette existante hors lot.
- Sub-agent Critique finale : à corriger initialement, puis OK après correction. Il a identifié le garde-fou runtime manquant pour montants plats non positifs ; corrigé et testé. Il a aussi signalé `AGENTS.md` hors scope, déjà modifié avant le lot.

## État git final
État observé après création du rapport :

```text
 M AGENTS.md
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_session_scheduler.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_bag_menu_model_test.dart
 M packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/battle_potion_apply_runtime_test.dart
 M packages/map_runtime/test/battle_turn_presentation_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/lot-9h-battle-bag-max-potion-support-report.md
```

Stat du diff code/test du lot, hors `AGENTS.md` et hors rapport :

```text
 packages/map_battle/lib/src/battle_action.dart     |  87 +++++++-
 packages/map_battle/lib/src/battle_session.dart    | 123 ++++++++---
 .../lib/src/battle_session_scheduler.dart          |  10 +-
 packages/map_battle/test/battle_session_test.dart  | 227 +++++++++++++++++++++
 .../runtime_battle_bag_hp_heal_item_apply.dart     |  63 ++++--
 .../presentation/flame/battle_bag_menu_model.dart  |   6 +-
 .../flame/battle_command_panel_component.dart      |  10 +
 .../flame/battle_overlay_component.dart            |   5 +-
 .../src/presentation/flame/playable_map_game.dart  |  10 +-
 .../test/battle_bag_menu_model_test.dart           |  68 +++++-
 .../battle_medicine_target_menu_model_test.dart    |  27 +++
 .../test/battle_overlay_component_test.dart        | 187 +++++++++++++++++
 .../test/battle_potion_apply_runtime_test.dart     | 223 ++++++++++++++++++++
 .../test/battle_turn_presentation_test.dart        | 106 ++++++++++
 .../test/wild_battle_end_to_end_flow_test.dart     | 118 +++++++++++
 15 files changed, 1209 insertions(+), 61 deletions(-)
```

Aucune opération Git d'écriture n'a été faite : pas de commit, amend, merge, rebase, push, tag, reset, stash, cherry-pick.

## Limites explicitement conservées
- Pas de registre d'items.
- Pas de catalogue runtime global.
- Pas de parsing textuel d'items dans le moteur battle.
- Pas d'`itemId` arbitraire au cœur du moteur battle.
- Pas d'Antidote, Revive, Full Restore, X Attack, held items, key items ou overworld items.
- Pas de modification du converter Showdown.
- Pas de modification Bubble/Bubble Beam.
- Pas de modification du bridge runtime -> battle des moves.
- Capture BAG conservée et couverte par les suites existantes.

## Auto-critique finale
- Le choix `BattleBagHpHealEffect` est plus honnête que `healAmount`, mais il marque probablement la limite saine de cette mini-famille. Le prochain objet HP heal non trivial doit déclencher un nouvel audit.
- Les commentaires ajoutés sont utiles pour les frontières de lot, mais le prompt pousse à beaucoup documenter ; il faudra éviter que les prochains lots accumulent trop de texte historique.
- `BattleActionBagHpHealItemUse` conserve une compat constructeur `healAmount` pour les tests/fixtures existants. C'est acceptable ici, mais il faudra éviter de l'étendre à `Max Potion` ou de l'exposer comme API générique.
- L'analyse complète `map_runtime` échoue sur une dette globale existante. Elle n'est pas liée au lot, mais elle limite la force du signal "analyse verte" au package entier.
- `AGENTS.md` reste modifié hors scope ; je ne l'ai pas revert car c'était déjà présent avant et les règles interdisent de supprimer des changements utilisateur non liés.

## Faut-il s'arrêter après ce lot ?
Oui, il faut probablement s'arrêter et ré-auditer avant d'ajouter un autre objet. La mini-famille HP heal à quatre objets reste saine parce qu'elle couvre deux effets simples : soin plat et restore-to-full. Ajouter `Full Restore`, `Revive`, stat items, status cures ou objets mixtes changerait la nature du seam et risquerait de devenir un framework d'items déguisé.

Il serait encore acceptable d'ajouter un heal plat strictement identique si un lot futur le demande explicitement, mais seulement après vérifier que la famille reste fermée et que la sémantique n'ajoute pas status/PP/revive/held behavior.

## Risques restants
- Full Restore et Revive ne doivent pas réutiliser aveuglément ce seam.
- La compat `healAmount` du constructeur battle doit rester transitoire/strictement plate.
- Les tests end-to-end prouvent un scénario actif simple ; les réserves sont couvertes côté runtime apply, mais pas par un E2E PlayableMapGame dédié à Max Potion sur réserve.

## Prochaines étapes proposées sans implémentation
- Avant tout nouvel item : mini-audit d'architecture sur la famille exacte visée.
- Nettoyer séparément les 325 issues de `flutter analyze` global runtime si l'équipe veut un signal CI plus net.
- Ajouter un test E2E PlayableMapGame pour medicine sur réserve si les futurs lots exploitent plus souvent les réserves.

## Annexe — diff unifié exhaustif des fichiers code/test touchés

```diff
diff --git a/packages/map_battle/lib/src/battle_action.dart b/packages/map_battle/lib/src/battle_action.dart
index 9e3c5fd8..e8c163b2 100644
--- a/packages/map_battle/lib/src/battle_action.dart
+++ b/packages/map_battle/lib/src/battle_action.dart
@@ -122,10 +122,11 @@ class BattleActionRun extends BattleAction {
 
 /// Famille ultra-bornée d'objets de soin HP supportés en BAG battle.
 ///
-/// Lot 9-f factorise seulement ce qui devenait absurde à dupliquer :
+/// Lot 9-h factorise seulement ce qui devenait absurde à dupliquer :
 /// - `potion`
 /// - `super-potion`
 /// - `hyper-potion`
+/// - `max-potion`
 ///
 /// Garde-fous de frontière :
 /// - ce n'est pas un catalogue runtime d'objets ;
@@ -135,39 +136,90 @@ class BattleActionRun extends BattleAction {
 enum BattleBagHpHealItemKind {
   potion,
   superPotion,
-  hyperPotion;
+  hyperPotion,
+  maxPotion;
 
   String get itemId => switch (this) {
         BattleBagHpHealItemKind.potion => 'potion',
         BattleBagHpHealItemKind.superPotion => 'super-potion',
         BattleBagHpHealItemKind.hyperPotion => 'hyper-potion',
+        BattleBagHpHealItemKind.maxPotion => 'max-potion',
       };
 
   String get label => switch (this) {
         BattleBagHpHealItemKind.potion => 'Potion',
         BattleBagHpHealItemKind.superPotion => 'Super Potion',
         BattleBagHpHealItemKind.hyperPotion => 'Hyper Potion',
+        BattleBagHpHealItemKind.maxPotion => 'Max Potion',
       };
 }
 
-/// Utiliser un objet BAG de soin HP plat sur un membre du lineup joueur.
+/// Effet de soin HP porté par la mini-famille BAG battle.
+///
+/// Lot 9-h garde ce modèle minuscule pour une seule raison : `Max Potion`
+/// soigne jusqu'au maximum et ne doit pas être représentée comme un montant
+/// plat arbitraire.
+sealed class BattleBagHpHealEffect {
+  const BattleBagHpHealEffect();
+}
+
+/// Effet strictement plat pour `Potion`, `Super Potion` et `Hyper Potion`.
+///
+/// Le montant reste porté par l'action afin que la timeline battle décrive le
+/// tour réellement committé, sans relire un catalogue d'items depuis le moteur.
+final class BattleBagFlatHpHealEffect extends BattleBagHpHealEffect {
+  const BattleBagFlatHpHealEffect(this.amount)
+      : assert(amount > 0, 'Flat HP-heal item amount must stay positive.');
+
+  final int amount;
+}
+
+/// Effet spécifique à `Max Potion` : restaurer la cible à ses PV maximum.
+///
+/// Ce type existe pour éviter le faux raccourci `healAmount: 999` ou
+/// `healAmount: maxHp`. L'amount vraiment rendu reste calculé au moment de la
+/// résolution via `hpAfter - hpBefore`.
+final class BattleBagRestoreToFullHpHealEffect extends BattleBagHpHealEffect {
+  const BattleBagRestoreToFullHpHealEffect();
+}
+
+/// Utiliser un objet BAG de soin HP sur un membre du lineup joueur.
 ///
 /// Cette action reste volontairement très étroite :
-/// - elle couvre seulement `Potion` + `Super Potion` + `Hyper Potion` ;
+/// - elle couvre seulement `Potion` + `Super Potion` + `Hyper Potion` +
+///   `Max Potion` ;
 /// - elle ne lit jamais le bag ;
 /// - elle n'ouvre pas un système générique d'items battle ;
-/// - elle existe uniquement pour rendre ces trois objets honnêtes comme vraies
+/// - elle existe uniquement pour rendre ces objets honnêtes comme vraies
 ///   actions de tour committées et visibles dans la timeline.
 class BattleActionBagHpHealItemUse extends BattleAction {
   const BattleActionBagHpHealItemUse({
     required this.itemKind,
     required this.targetLineupIndex,
-    required this.healAmount,
-  }) : assert(healAmount > 0, 'HP-heal item healAmount must stay positive.');
+    this.healAmount,
+    this.effect,
+  })  : assert(
+          (healAmount == null) != (effect == null),
+          'Provide exactly one of healAmount or effect.',
+        ),
+        assert(
+          healAmount == null || healAmount > 0,
+          'HP-heal item healAmount must stay positive.',
+        ),
+        assert(
+          itemKind != BattleBagHpHealItemKind.maxPotion ||
+              effect is BattleBagRestoreToFullHpHealEffect,
+          'Max Potion must use a restore-to-full HP heal effect.',
+        ),
+        assert(
+          itemKind == BattleBagHpHealItemKind.maxPotion ||
+              effect is! BattleBagRestoreToFullHpHealEffect,
+          'Restore-to-full HP heal effect is reserved for Max Potion.',
+        );
 
   /// L'objet précis réellement utilisé.
   ///
-  /// Le `kind` reste borné à trois cas, ce qui évite de transporter un
+  /// Le `kind` reste borné à quatre cas, ce qui évite de transporter un
   /// `itemId` stringly-typed arbitraire dans le moteur.
   final BattleBagHpHealItemKind itemKind;
 
@@ -177,11 +229,26 @@ class BattleActionBagHpHealItemUse extends BattleAction {
   /// tout couplage fragile à un index visuel d'overlay ou à un slot save.
   final int targetLineupIndex;
 
-  /// Quantité de soin plate réellement portée par cette action.
+  /// Ancienne forme plate conservée pour les objets à montant fixe.
+  ///
+  /// Ce champ reste nullable pour préserver le constructeur `const` historique
+  /// utilisé par quelques tests et fixtures. Les consommateurs du moteur
+  /// doivent utiliser [resolvedEffect] afin de ne pas confondre `Max Potion`
+  /// avec un montant plat.
+  final int? healAmount;
+
+  /// Effet de soin explicitement porté par cette action.
   ///
   /// Le runtime décide encore si l'objet est disponible dans le bag ;
   /// le moteur ne consomme ici que l'effet déjà autorisé.
-  final int healAmount;
+  final BattleBagHpHealEffect? effect;
+
+  /// Effet normalisé utilisé par le scheduler et la résolution.
+  ///
+  /// Le getter garde la compatibilité avec le `healAmount` historique sans
+  /// réintroduire ce concept dans `Max Potion`.
+  BattleBagHpHealEffect get resolvedEffect =>
+      effect ?? BattleBagFlatHpHealEffect(healAmount!);
 }
 
 /// Perdre honnêtement son tour à cause d'une recharge forcée.
diff --git a/packages/map_battle/lib/src/battle_session.dart b/packages/map_battle/lib/src/battle_session.dart
index 9b3f1520..f5968fbe 100644
--- a/packages/map_battle/lib/src/battle_session.dart
+++ b/packages/map_battle/lib/src/battle_session.dart
@@ -272,16 +272,20 @@ class BattleSession {
   ///
   /// Lot 9-f conserve cette façade explicite pour éviter de vendre une API
   /// générique d'objets : l'implémentation factorise en interne avec
-  /// `Super Potion` et `Hyper Potion`, mais l'appelant reste bien sur un
-  /// objet concret.
+  /// `Super Potion`, `Hyper Potion` et `Max Potion`, mais l'appelant reste bien
+  /// sur un objet concret.
   BattleSession applyPotionTurn({
     required int targetLineupIndex,
     required int healAmount,
   }) {
+    _requirePositiveBagHpHealAmount(
+      itemLabel: BattleBagHpHealItemKind.potion.label,
+      healAmount: healAmount,
+    );
     return _applyBagHpHealItemTurn(
       itemKind: BattleBagHpHealItemKind.potion,
       targetLineupIndex: targetLineupIndex,
-      healAmount: healAmount,
+      effect: BattleBagFlatHpHealEffect(healAmount),
     );
   }
 
@@ -295,10 +299,14 @@ class BattleSession {
     required int targetLineupIndex,
     required int healAmount,
   }) {
+    _requirePositiveBagHpHealAmount(
+      itemLabel: BattleBagHpHealItemKind.superPotion.label,
+      healAmount: healAmount,
+    );
     return _applyBagHpHealItemTurn(
       itemKind: BattleBagHpHealItemKind.superPotion,
       targetLineupIndex: targetLineupIndex,
-      healAmount: healAmount,
+      effect: BattleBagFlatHpHealEffect(healAmount),
     );
   }
 
@@ -313,15 +321,34 @@ class BattleSession {
     required int targetLineupIndex,
     required int healAmount,
   }) {
+    _requirePositiveBagHpHealAmount(
+      itemLabel: BattleBagHpHealItemKind.hyperPotion.label,
+      healAmount: healAmount,
+    );
     return _applyBagHpHealItemTurn(
       itemKind: BattleBagHpHealItemKind.hyperPotion,
       targetLineupIndex: targetLineupIndex,
-      healAmount: healAmount,
+      effect: BattleBagFlatHpHealEffect(healAmount),
+    );
+  }
+
+  /// Commit une vraie action de tour `Max Potion`.
+  ///
+  /// Contrairement aux trois objets précédents, cette façade ne prend pas de
+  /// `healAmount` : le lot 9-h modélise explicitement "restore-to-full" pour ne
+  /// pas déguiser `Max Potion` en soin plat arbitraire.
+  BattleSession applyMaxPotionTurn({
+    required int targetLineupIndex,
+  }) {
+    return _applyBagHpHealItemTurn(
+      itemKind: BattleBagHpHealItemKind.maxPotion,
+      targetLineupIndex: targetLineupIndex,
+      effect: const BattleBagRestoreToFullHpHealEffect(),
     );
   }
 
   /// Commit une vraie action de tour pour la famille ultra-bornée
-  /// `Potion` + `Super Potion` + `Hyper Potion`.
+  /// `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`.
   ///
   /// Ce helper interne factorise seulement ce qui était devenu duplication :
   /// - même validation de requête ;
@@ -333,7 +360,7 @@ class BattleSession {
   BattleSession _applyBagHpHealItemTurn({
     required BattleBagHpHealItemKind itemKind,
     required int targetLineupIndex,
-    required int healAmount,
+    required BattleBagHpHealEffect effect,
   }) {
     final request = decisionRequest;
     if (request is! BattleTurnChoiceRequest) {
@@ -342,13 +369,10 @@ class BattleSession {
         '(request=${request.runtimeType}).',
       );
     }
-    if (healAmount <= 0) {
-      throw ArgumentError.value(
-        healAmount,
-        'healAmount',
-        '${itemKind.label} healAmount must stay strictly positive.',
-      );
-    }
+    _requireBagHpHealEffectMatchesItemKind(
+      itemKind: itemKind,
+      effect: effect,
+    );
 
     _requireUsableBagHpHealItemTarget(
       side: state.playerSide,
@@ -359,7 +383,7 @@ class BattleSession {
       playerAction: BattleActionBagHpHealItemUse(
         itemKind: itemKind,
         targetLineupIndex: targetLineupIndex,
-        healAmount: healAmount,
+        effect: effect,
       ),
     );
   }
@@ -821,26 +845,30 @@ class BattleSession {
     required BattleBagHpHealItemKind itemKind,
     required BattleSideState side,
     required int targetLineupIndex,
-    required int healAmount,
+    required BattleBagHpHealEffect effect,
   }) {
     if (side.id != BattleSideId.player) {
       throw StateError(
-        'BattleActionBagHpHealItemUse reste limité au côté joueur dans le lot 9-f.',
-      );
-    }
-    if (healAmount <= 0) {
-      throw ArgumentError.value(
-        healAmount,
-        'healAmount',
-        '${itemKind.label} healAmount must stay strictly positive.',
+        'BattleActionBagHpHealItemUse reste limité au côté joueur dans le lot 9-h.',
       );
     }
+    _requireBagHpHealEffectMatchesItemKind(
+      itemKind: itemKind,
+      effect: effect,
+    );
 
     final targetCombatant = _requireUsableBagHpHealItemTarget(
       side: side,
       targetLineupIndex: targetLineupIndex,
     );
-    final healedCombatant = targetCombatant.withHeal(healAmount);
+    final healedCombatant = switch (effect) {
+      BattleBagFlatHpHealEffect(:final amount) => targetCombatant.withHeal(
+          amount,
+        ),
+      BattleBagRestoreToFullHpHealEffect() => targetCombatant.withHeal(
+          targetCombatant.maxHp - targetCombatant.currentHp,
+        ),
+    };
 
     return _ResolvedBagHpHealItemUseAction(
       side: _replacePlayerCombatantByLineupIndex(
@@ -858,6 +886,51 @@ class BattleSession {
     );
   }
 
+  void _requireBagHpHealEffectMatchesItemKind({
+    required BattleBagHpHealItemKind itemKind,
+    required BattleBagHpHealEffect effect,
+  }) {
+    // Garde-fou runtime, pas seulement `assert` debug :
+    // - les trois premiers objets restent des soins plats ;
+    // - `Max Potion` reste le seul restore-to-full ;
+    // - on refuse donc les combinaisons qui mentiraient à la timeline ou au
+    //   write-back runtime en release.
+    switch (effect) {
+      case BattleBagFlatHpHealEffect(:final amount):
+        _requirePositiveBagHpHealAmount(
+          itemLabel: itemKind.label,
+          healAmount: amount,
+        );
+        if (itemKind == BattleBagHpHealItemKind.maxPotion) {
+          throw StateError(
+            'Max Potion must use a restore-to-full HP heal effect.',
+          );
+        }
+      case BattleBagRestoreToFullHpHealEffect():
+        if (itemKind != BattleBagHpHealItemKind.maxPotion) {
+          throw StateError(
+            'Restore-to-full HP heal effect is reserved for Max Potion.',
+          );
+        }
+    }
+  }
+
+  void _requirePositiveBagHpHealAmount({
+    required String itemLabel,
+    required int healAmount,
+  }) {
+    // Validation runtime volontairement dupliquée par rapport aux `assert` du
+    // value object : les builds release désactivent les asserts, mais un soin
+    // plat nul ou négatif mentirait à la timeline et pourrait baisser les PV.
+    if (healAmount <= 0) {
+      throw ArgumentError.value(
+        healAmount,
+        'healAmount',
+        '$itemLabel healAmount must stay strictly positive.',
+      );
+    }
+  }
+
   int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
     for (var i = 0; i < reserve.length; i++) {
       if (!reserve[i].isFainted) {
diff --git a/packages/map_battle/lib/src/battle_session_scheduler.dart b/packages/map_battle/lib/src/battle_session_scheduler.dart
index faedac7b..aa8d5815 100644
--- a/packages/map_battle/lib/src/battle_session_scheduler.dart
+++ b/packages/map_battle/lib/src/battle_session_scheduler.dart
@@ -450,11 +450,11 @@ void _executeActionQueueStep({
       case BattleActionBagHpHealItemUse(
         :final itemKind,
         :final targetLineupIndex,
-        :final healAmount,
+        :final resolvedEffect,
       )) {
     if (step.side != BattleSideId.player) {
       throw StateError(
-        'BattleActionBagHpHealItemUse reste player-only dans le lot 9-f.',
+        'BattleActionBagHpHealItemUse reste player-only dans le lot 9-h.',
       );
     }
 
@@ -462,7 +462,7 @@ void _executeActionQueueStep({
       itemKind: itemKind,
       side: actingSide,
       targetLineupIndex: targetLineupIndex,
-      healAmount: healAmount,
+      effect: resolvedEffect,
     );
     turn.updateSide(step.side, resolution.side);
     turn.bagHpHealItemEvents.add(resolution.event);
@@ -815,8 +815,8 @@ int _priorityForResolvedAction(BattleAction action) {
     // - cela ne prétend toujours pas modéliser la taxonomie Showdown complète
     //   des priorités de switch.
     //
-    // Lots 9-e / 9-f / 9-g ajoutent un seul micro-slice d'objets :
-    // - `Potion`, `Super Potion` et `Hyper Potion` deviennent de vraies
+    // Lots 9-e à 9-h ajoutent un seul micro-slice d'objets :
+    // - `Potion`, `Super Potion`, `Hyper Potion` et `Max Potion` deviennent de vraies
     //   actions de tour ;
     // - elles résolvent avant les moves actuellement supportés ;
     // - on refuse pourtant d'ouvrir une échelle générique de priorités items.
diff --git a/packages/map_battle/test/battle_session_test.dart b/packages/map_battle/test/battle_session_test.dart
index 07541e28..03191889 100644
--- a/packages/map_battle/test/battle_session_test.dart
+++ b/packages/map_battle/test/battle_session_test.dart
@@ -1222,5 +1222,232 @@ void main() {
         isA<BattleTurnExecutionEvent>(),
       );
     });
+
+    test(
+        'applyMaxPotionTurn commits a real turn and records a max potion timeline event',
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
+      final updatedSession = session.applyMaxPotionTurn(
+        targetLineupIndex: 0,
+      );
+
+      expect(updatedSession.state.currentTurn, isNotNull);
+      expect(updatedSession.state.player.currentHp, equals(260));
+      expect(
+        updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>()
+            .having(
+              (action) => action.itemKind,
+              'itemKind',
+              equals(BattleBagHpHealItemKind.maxPotion),
+            )
+            .having(
+              (action) => action.effect,
+              'effect',
+              isA<BattleBagRestoreToFullHpHealEffect>(),
+            ),
+      );
+      expect(
+        updatedSession.state.currentTurn!.enemyAction,
+        isA<BattleActionFight>(),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents,
+        hasLength(1),
+      );
+      expect(
+        updatedSession.state.currentTurn!.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.maxPotion),
+      );
+      expect(
+        updatedSession
+            .state.currentTurn!.bagHpHealItemEvents.single.healedAmount,
+        equals(248),
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
+
+    test(
+        'applyMaxPotionTurn rejects invalid targets instead of faking a committed item turn',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 40,
+            currentHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'tackle', name: 'Tackle', power: 40),
+            ],
+          ),
+          playerReservePokemon: const <BattleCombatantData>[
+            BattleCombatantData(
+              speciesId: 'benchmate',
+              level: 10,
+              maxHp: 35,
+              currentHp: 0,
+              lineupIndex: 1,
+              stats: _neutralBattleStats,
+              moves: <BattleMoveData>[
+                BattleMoveData(id: 'wait', name: 'Wait', power: 0),
+              ],
+            ),
+          ],
+          enemyPokemon: const BattleCombatantData(
+            speciesId: 'sparkitten',
+            level: 10,
+            maxHp: 40,
+            lineupIndex: 0,
+            stats: _neutralBattleStats,
+            moves: <BattleMoveData>[
+              BattleMoveData(id: 'wait', name: 'Wait', power: 0),
+            ],
+          ),
+          isTrainerBattle: true,
+          trainerId: 'trainer_1',
+        ),
+      );
+
+      expect(
+        () => session.applyMaxPotionTurn(targetLineupIndex: 0),
+        throwsA(isA<StateError>()),
+      );
+      expect(
+        () => session.applyMaxPotionTurn(targetLineupIndex: 1),
+        throwsA(isA<StateError>()),
+      );
+      expect(session.state.currentTurn, isNull);
+      expect(session.state.player.currentHp, equals(40));
+      expect(session.state.playerReserve.single.currentHp, equals(0));
+    });
+
+    test(
+        'BattleActionBagHpHealItemUse keeps restore-to-full semantics reserved for max potion',
+        () {
+      expect(
+        () => BattleActionBagHpHealItemUse(
+          itemKind: BattleBagHpHealItemKind.potion,
+          targetLineupIndex: 0,
+          effect: const BattleBagRestoreToFullHpHealEffect(),
+        ),
+        throwsA(isA<AssertionError>()),
+      );
+      expect(
+        () => BattleActionBagHpHealItemUse(
+          itemKind: BattleBagHpHealItemKind.maxPotion,
+          targetLineupIndex: 0,
+          healAmount: 200,
+        ),
+        throwsA(isA<AssertionError>()),
+      );
+      expect(
+        const BattleActionBagHpHealItemUse(
+          itemKind: BattleBagHpHealItemKind.maxPotion,
+          targetLineupIndex: 0,
+          effect: BattleBagRestoreToFullHpHealEffect(),
+        ).effect,
+        isA<BattleBagRestoreToFullHpHealEffect>(),
+      );
+    });
+
+    test(
+        'flat bag hp heal facades reject non-positive amounts before committing a turn',
+        () {
+      final session = createBattleSession(
+        BattleSetup(
+          playerPokemon: const BattleCombatantData(
+            speciesId: 'sproutle',
+            level: 10,
+            maxHp: 80,
+            currentHp: 20,
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
+              BattleMoveData(id: 'wait', name: 'Wait', power: 0),
+            ],
+          ),
+          isTrainerBattle: true,
+          trainerId: 'trainer_1',
+        ),
+      );
+
+      expect(
+        () => session.applyPotionTurn(
+          targetLineupIndex: 0,
+          healAmount: 0,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => session.applySuperPotionTurn(
+          targetLineupIndex: 0,
+          healAmount: -1,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(
+        () => session.applyHyperPotionTurn(
+          targetLineupIndex: 0,
+          healAmount: 0,
+        ),
+        throwsA(isA<ArgumentError>()),
+      );
+      expect(session.state.currentTurn, isNull);
+      expect(session.state.player.currentHp, equals(20));
+    });
   });
 }
diff --git a/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart b/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
index ce3589d1..276d430f 100644
--- a/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
+++ b/packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
@@ -28,12 +28,12 @@ class RuntimeBattleBagHpHealItemApplyResult {
 
 /// Runtime owner du mini-slice BAG HP-heal battle.
 ///
-/// Le renommage devient utile au lot 9-g :
-/// - avec `Potion` + `Super Potion` + `Hyper Potion`, le nom historique
-///   `runtime_battle_potion_apply.dart` devient trop mensonger ;
+/// Le renommage reste utile au lot 9-h :
+/// - avec `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`, le nom
+///   historique `runtime_battle_potion_apply.dart` serait trop mensonger ;
 /// - le blast radius reste raisonnable car ce seam n'est importé qu'en
 ///   interne par le runtime et ses tests ;
-/// - on reste malgré tout strictement borné à trois objets, pas à une famille
+/// - on reste malgré tout strictement borné à quatre objets, pas à une famille
 ///   ouverte de medicines.
 RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattlePotionUse({
   required BattleSession session,
@@ -91,6 +91,25 @@ RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleHyperPotionUse({
   );
 }
 
+/// Support explicite ajouté par le lot 9-h.
+///
+/// `Max Potion` partage le même mini-slice BAG HP-heal, mais son effet reste
+/// "restore-to-full" et non un montant plat codé côté runtime.
+RuntimeBattleBagHpHealItemApplyResult? tryApplyRuntimeBattleMaxPotionUse({
+  required BattleSession session,
+  required GameState gameState,
+  required RuntimeActiveBattleContext context,
+  required int targetLineupIndex,
+}) {
+  return _tryApplyRuntimeBattleBagHpHealItemUse(
+    session: session,
+    gameState: gameState,
+    context: context,
+    itemSpec: _runtimeItemSpec(BattleBagHpHealItemKind.maxPotion),
+    targetLineupIndex: targetLineupIndex,
+  );
+}
+
 RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
   required BattleSession session,
   required GameState gameState,
@@ -119,7 +138,14 @@ RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
     return null;
   }
 
-  final healedCombatant = targetCombatant.withHeal(itemSpec.healAmount);
+  final healedCombatant = switch (itemSpec.effect) {
+    BattleBagFlatHpHealEffect(:final amount) => targetCombatant.withHeal(
+        amount,
+      ),
+    BattleBagRestoreToFullHpHealEffect() => targetCombatant.withHeal(
+        targetCombatant.maxHp - targetCombatant.currentHp,
+      ),
+  };
   final healedAmount = healedCombatant.currentHp - targetCombatant.currentHp;
   if (healedAmount <= 0) {
     return null;
@@ -128,15 +154,18 @@ RuntimeBattleBagHpHealItemApplyResult? _tryApplyRuntimeBattleBagHpHealItemUse({
   final updatedSession = switch (itemSpec.kind) {
     BattleBagHpHealItemKind.potion => session.applyPotionTurn(
         targetLineupIndex: targetLineupIndex,
-        healAmount: itemSpec.healAmount,
+        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
       ),
     BattleBagHpHealItemKind.superPotion => session.applySuperPotionTurn(
         targetLineupIndex: targetLineupIndex,
-        healAmount: itemSpec.healAmount,
+        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
       ),
     BattleBagHpHealItemKind.hyperPotion => session.applyHyperPotionTurn(
         targetLineupIndex: targetLineupIndex,
-        healAmount: itemSpec.healAmount,
+        healAmount: (itemSpec.effect as BattleBagFlatHpHealEffect).amount,
+      ),
+    BattleBagHpHealItemKind.maxPotion => session.applyMaxPotionTurn(
+        targetLineupIndex: targetLineupIndex,
       ),
   };
   final updatedGameState = _applyCommittedBagHpHealItemTurnToRuntimeState(
@@ -172,7 +201,7 @@ BattleCombatant? _findPlayerCombatantByLineupIndex({
   return null;
 }
 
-// Le fil 9-d -> 9-g garde le runtime propriétaire de la vérité hors moteur :
+// Le fil 9-d -> 9-h garde le runtime propriétaire de la vérité hors moteur :
 // - write-back réel de toute la lineup engagée ;
 // - consommation réelle du bon item de bag ;
 // - aucune divergence overlay-only.
@@ -252,21 +281,27 @@ _RuntimeBattleBagHpHealItemSpec _runtimeItemSpec(
         kind: BattleBagHpHealItemKind.potion,
         itemId: 'potion',
         label: 'Potion',
-        healAmount: _runtimeBattlePotionHealAmount,
+        effect: BattleBagFlatHpHealEffect(_runtimeBattlePotionHealAmount),
       ),
     BattleBagHpHealItemKind.superPotion =>
       const _RuntimeBattleBagHpHealItemSpec(
         kind: BattleBagHpHealItemKind.superPotion,
         itemId: 'super-potion',
         label: 'Super Potion',
-        healAmount: _runtimeBattleSuperPotionHealAmount,
+        effect: BattleBagFlatHpHealEffect(_runtimeBattleSuperPotionHealAmount),
       ),
     BattleBagHpHealItemKind.hyperPotion =>
       const _RuntimeBattleBagHpHealItemSpec(
         kind: BattleBagHpHealItemKind.hyperPotion,
         itemId: 'hyper-potion',
         label: 'Hyper Potion',
-        healAmount: _runtimeBattleHyperPotionHealAmount,
+        effect: BattleBagFlatHpHealEffect(_runtimeBattleHyperPotionHealAmount),
+      ),
+    BattleBagHpHealItemKind.maxPotion => const _RuntimeBattleBagHpHealItemSpec(
+        kind: BattleBagHpHealItemKind.maxPotion,
+        itemId: 'max-potion',
+        label: 'Max Potion',
+        effect: BattleBagRestoreToFullHpHealEffect(),
       ),
   };
 }
@@ -276,11 +311,11 @@ class _RuntimeBattleBagHpHealItemSpec {
     required this.kind,
     required this.itemId,
     required this.label,
-    required this.healAmount,
+    required this.effect,
   });
 
   final BattleBagHpHealItemKind kind;
   final String itemId;
   final String label;
-  final int healAmount;
+  final BattleBagHpHealEffect effect;
 }
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
index b5c0c4cb..3654964c 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
@@ -267,10 +267,11 @@ BattleBagItemKind _classifyBagItem(BagEntry bagEntry) {
 }
 
 bool _isSupportedMedicine(BagEntry bagEntry) {
-  // Lot 9-g factorise ici le strict minimum utile :
+  // Lot 9-h factorise ici le strict minimum utile :
   // - `potion`
   // - `super-potion`
   // - `hyper-potion`
+  // - `max-potion`
   //
   // On ne bascule pas vers un registre d'items ni vers un catalogue runtime.
   if (bagEntry.categoryId != 'medicine') {
@@ -278,7 +279,8 @@ bool _isSupportedMedicine(BagEntry bagEntry) {
   }
   return bagEntry.itemId == 'potion' ||
       bagEntry.itemId == 'super-potion' ||
-      bagEntry.itemId == 'hyper-potion';
+      bagEntry.itemId == 'hyper-potion' ||
+      bagEntry.itemId == 'max-potion';
 }
 
 BattleBagMenuDisabledReason _captureDisabledReason({
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
index e88f8187..339b6970 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
@@ -1670,6 +1670,7 @@ _BattleBagItemIconKind _bagItemIconKind(String itemId) {
     'potion' => _BattleBagItemIconKind.potion,
     'super-potion' => _BattleBagItemIconKind.superPotion,
     'hyper-potion' => _BattleBagItemIconKind.hyperPotion,
+    'max-potion' => _BattleBagItemIconKind.maxPotion,
     _ => _BattleBagItemIconKind.unsupported,
   };
 }
@@ -1742,6 +1743,14 @@ void _paintBagItemIcon(
         capColor: const Color(0xFFF0B96C),
         enabled: enabled,
       );
+    case _BattleBagItemIconKind.maxPotion:
+      _paintBottleIcon(
+        canvas,
+        rect: rect,
+        liquidColor: const Color(0xFFFFD15C),
+        capColor: const Color(0xFF7BCF84),
+        enabled: enabled,
+      );
     case _BattleBagItemIconKind.unsupported:
       canvas.drawRRect(
         RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(6)),
@@ -2969,5 +2978,6 @@ enum _BattleBagItemIconKind {
   potion,
   superPotion,
   hyperPotion,
+  maxPotion,
   unsupported,
 }
diff --git a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
index 14613629..8aa061ab 100644
--- a/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
@@ -374,6 +374,7 @@ String? _overlaySupportedMedicineLabel(String itemId) {
     'potion' => 'Potion',
     'super-potion' => 'Super Potion',
     'hyper-potion' => 'Hyper Potion',
+    'max-potion' => 'Max Potion',
     _ => null,
   };
 }
@@ -1769,10 +1770,10 @@ class BattleOverlayComponent extends PositionComponent {
       return false;
     }
 
-    // Lots 9-e / 9-f / 9-g gardent l'overlay strictement borné au shell de
+    // Lots 9-e à 9-h gardent l'overlay strictement borné au shell de
     // ciblage :
     // - le parent runtime commit le vrai tour pour `Potion`, `Super Potion`
-    //   et `Hyper Potion` ;
+    //   `Hyper Potion` et `Max Potion` ;
     // - l'overlay ne patche plus sa session localement ;
     // - cela évite de mentir sur l'ordre du tour et garde `PlayableMapGame`
     //   propriétaire unique du vrai BattleSession / GameState.
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index d79f17f3..4fcfb72d 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -4117,11 +4117,11 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
 
     _isBattleResolving = true;
     try {
-      // Lots 9-e / 9-f / 9-g gardent `PlayableMapGame` comme propriétaire honnête
+      // Lots 9-e à 9-h gardent `PlayableMapGame` comme propriétaire honnête
       // du runtime autour du moteur battle :
       // - le moteur battle produit un `currentTurn` et une timeline honnêtes ;
       // - le runtime reste propriétaire du bag réel et du write-back party ;
-      // - on reste borné à `Potion` + `Super Potion` + `Hyper Potion`,
+      // - on reste borné à `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`,
       //   sans API item générique.
       final result = switch (action.itemId) {
         'potion' => tryApplyRuntimeBattlePotionUse(
@@ -4142,6 +4142,12 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
             context: activeBattleContext,
             targetLineupIndex: entry.lineupIndex,
           ),
+        'max-potion' => tryApplyRuntimeBattleMaxPotionUse(
+            session: battleSession,
+            gameState: _gameState,
+            context: activeBattleContext,
+            targetLineupIndex: entry.lineupIndex,
+          ),
         _ => null,
       };
       if (result == null) {
diff --git a/packages/map_runtime/test/battle_bag_menu_model_test.dart b/packages/map_runtime/test/battle_bag_menu_model_test.dart
index cd804cb4..e1ad8150 100644
--- a/packages/map_runtime/test/battle_bag_menu_model_test.dart
+++ b/packages/map_runtime/test/battle_bag_menu_model_test.dart
@@ -503,6 +503,60 @@ void main() {
       );
     });
 
+    test(
+        'supported max potion is selectable in a free turn and opens a medicine target action',
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
+                itemId: 'max-potion',
+                categoryId: 'medicine',
+                quantity: 3,
+              ),
+            ],
+          ),
+        ),
+        session: session,
+      );
+
+      final entry = model.entries.single;
+      expect(entry.kind, equals(BattleBagItemKind.medicine));
+      expect(entry.quantity, equals(3));
+      expect(entry.isSelectable, isTrue);
+      expect(entry.disabledReason, isNull);
+      expect(
+        entry.action,
+        isA<BattleBagMenuActionMedicineTarget>()
+            .having(
+              (action) => action.itemId,
+              'itemId',
+              equals('max-potion'),
+            )
+            .having(
+              (action) => action.categoryId,
+              'categoryId',
+              equals('medicine'),
+            )
+            .having((action) => action.quantity, 'quantity', equals(3)),
+      );
+    });
+
     test('groups battle bag entries by category for display order', () {
       final session = _session(
         player: _combatant(
@@ -529,6 +583,11 @@ void main() {
                 categoryId: 'medicine',
                 quantity: 1,
               ),
+              _entry(
+                itemId: 'max-potion',
+                categoryId: 'medicine',
+                quantity: 1,
+              ),
               _entry(itemId: 'x-attack', categoryId: 'items', quantity: 1),
             ],
           ),
@@ -538,7 +597,13 @@ void main() {
 
       expect(
         model.entries.map((entry) => entry.itemId),
-        <String>['poke-ball', 'potion', 'super-potion', 'x-attack'],
+        <String>[
+          'poke-ball',
+          'max-potion',
+          'potion',
+          'super-potion',
+          'x-attack',
+        ],
       );
       expect(
         model.entries.map((entry) => entry.kind),
@@ -546,6 +611,7 @@ void main() {
           BattleBagItemKind.captureBall,
           BattleBagItemKind.medicine,
           BattleBagItemKind.medicine,
+          BattleBagItemKind.medicine,
           BattleBagItemKind.unsupported,
         ],
       );
diff --git a/packages/map_runtime/test/battle_medicine_target_menu_model_test.dart b/packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
index f0b70d1a..7d4a4c9a 100644
--- a/packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
+++ b/packages/map_runtime/test/battle_medicine_target_menu_model_test.dart
@@ -148,6 +148,33 @@ void main() {
       expect(model.hasSelectableEntries, isTrue);
     });
 
+    test('carries max potion metadata while preserving target selectability',
+        () {
+      final model = buildBattleMedicineTargetMenuModel(
+        session: _session(
+          player: _combatant(
+            speciesId: 'sproutle',
+            lineupIndex: 0,
+            currentHp: 15,
+            maxHp: 40,
+            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+          ),
+          enemy: _combatant(
+            speciesId: 'wild_enemy',
+            lineupIndex: 0,
+            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
+          ),
+        ),
+        itemId: 'max-potion',
+        categoryId: 'medicine',
+      );
+
+      expect(model.itemId, equals('max-potion'));
+      expect(model.categoryId, equals('medicine'));
+      expect(model.activeEntry.isSelectable, isTrue);
+      expect(model.activeEntry.disabledReason, isNull);
+    });
+
     test('full hp pokemon stay visible but non-selectable', () {
       final model = buildBattleMedicineTargetMenuModel(
         session: _session(
diff --git a/packages/map_runtime/test/battle_overlay_component_test.dart b/packages/map_runtime/test/battle_overlay_component_test.dart
index a8a0034d..fd947a9c 100644
--- a/packages/map_runtime/test/battle_overlay_component_test.dart
+++ b/packages/map_runtime/test/battle_overlay_component_test.dart
@@ -2142,6 +2142,193 @@ void main() {
       expect(overlay.currentPromptText, equals('sproutle récupère 200 PV.'));
     });
 
+    test(
+        'selecting a valid max potion target commits a real restore-to-full turn without dispatching a PlayerBattleChoice',
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
+              itemId: 'max-potion',
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
+            'max-potion' => tryApplyRuntimeBattleMaxPotionUse(
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
+      final playerAction = overlay.debugSession.state.currentTurn!.playerAction;
+      expect(
+        playerAction,
+        isA<BattleActionBagHpHealItemUse>()
+            .having(
+              (action) => action.itemKind,
+              'itemKind',
+              equals(BattleBagHpHealItemKind.maxPotion),
+            )
+            .having(
+              (action) => action.effect,
+              'effect',
+              isA<BattleBagRestoreToFullHpHealEffect>(),
+            ),
+      );
+      expect(overlay.debugSession.state.player.currentHp, equals(260));
+      expect(
+        overlay.debugGameState.party.members.first.currentHp,
+        equals(260),
+      );
+      expect(overlay.debugGameState.bag.entries, isEmpty);
+      expect(overlay.isTurnPresentationActive, isTrue);
+      expect(
+        overlay.currentPromptText,
+        equals('Joueur utilise Max Potion sur sproutle !'),
+      );
+      expect(overlay.currentMenuMode, BattleCommandMenuMode.bag);
+      expect(overlay.validateSelectedChoice(), isFalse);
+
+      overlay.updateTree(0.50);
+      expect(overlay.currentPromptText, equals('sproutle récupère 238 PV.'));
+    });
+
     test('full hp medicine targets stay visible but non-selectable', () async {
       final overlay = BattleOverlayComponent(
         session: _session(
diff --git a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
index a4f0b385..7fd11810 100644
--- a/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
+++ b/packages/map_runtime/test/battle_potion_apply_runtime_test.dart
@@ -448,6 +448,145 @@ void main() {
       expect(result.updatedGameState.bag.entries, isEmpty);
     });
 
+    test(
+        'max potion heals a damaged active target to max hp and consumes only max potion',
+        () {
+      final result = tryApplyRuntimeBattleMaxPotionUse(
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
+              BagEntry(
+                itemId: 'max-potion',
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
+      expect(result!.healedAmount, equals(248));
+      expect(
+        result.updatedSession.state.currentTurn!.playerAction,
+        isA<BattleActionBagHpHealItemUse>()
+            .having(
+              (action) => action.itemKind,
+              'itemKind',
+              equals(BattleBagHpHealItemKind.maxPotion),
+            )
+            .having(
+              (action) => action.effect,
+              'effect',
+              isA<BattleBagRestoreToFullHpHealEffect>(),
+            ),
+      );
+      expect(result.updatedSession.state.player.currentHp, equals(260));
+      expect(
+          result.updatedGameState.party.members.first.currentHp, equals(260));
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
+              quantity: 2,
+            ),
+            BagEntry(
+              itemId: 'max-potion',
+              categoryId: 'medicine',
+              quantity: 1,
+            ),
+          ],
+        ).normalized().entries,
+      );
+    });
+
+    test('max potion removes the bag entry when quantity reaches zero', () {
+      final result = tryApplyRuntimeBattleMaxPotionUse(
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
+                itemId: 'max-potion',
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
@@ -591,5 +730,89 @@ void main() {
       expect(faintedState.party.members.first.currentHp, equals(0));
       expect(faintedState.bag.entries.single.quantity, equals(1));
     });
+
+    test('max potion use does not affect a full hp or fainted target', () {
+      final fullHpState = _gameState(
+        bag: const Bag(
+          entries: <BagEntry>[
+            BagEntry(itemId: 'max-potion', categoryId: 'medicine', quantity: 1),
+          ],
+        ),
+        partyMembers: <PlayerPokemon>[
+          _partyMember(speciesId: 'sproutle', currentHp: 40),
+        ],
+      );
+      final fullHpSession = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 40,
+          maxHp: 40,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'enemy',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
+        ),
+      );
+
+      expect(
+        tryApplyRuntimeBattleMaxPotionUse(
+          session: fullHpSession,
+          gameState: fullHpState,
+          context: _context(
+            playerPartyIndex: 0,
+            lineupPartyIndices: const <int>[0],
+          ),
+          targetLineupIndex: 0,
+        ),
+        isNull,
+      );
+      expect(fullHpSession.state.player.currentHp, equals(40));
+      expect(fullHpState.party.members.first.currentHp, equals(40));
+      expect(fullHpState.bag.entries.single.quantity, equals(1));
+
+      final faintedState = _gameState(
+        bag: const Bag(
+          entries: <BagEntry>[
+            BagEntry(itemId: 'max-potion', categoryId: 'medicine', quantity: 1),
+          ],
+        ),
+        partyMembers: <PlayerPokemon>[
+          _partyMember(speciesId: 'sproutle', currentHp: 0),
+        ],
+      );
+      final faintedSession = _session(
+        player: _combatant(
+          speciesId: 'sproutle',
+          lineupIndex: 0,
+          currentHp: 0,
+          maxHp: 40,
+          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
+        ),
+        enemy: _combatant(
+          speciesId: 'enemy',
+          lineupIndex: 0,
+          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
+        ),
+      );
+
+      expect(
+        tryApplyRuntimeBattleMaxPotionUse(
+          session: faintedSession,
+          gameState: faintedState,
+          context: _context(
+            playerPartyIndex: 0,
+            lineupPartyIndices: const <int>[0],
+          ),
+          targetLineupIndex: 0,
+        ),
+        isNull,
+      );
+      expect(faintedSession.state.player.currentHp, equals(0));
+      expect(faintedState.party.members.first.currentHp, equals(0));
+      expect(faintedState.bag.entries.single.quantity, equals(1));
+    });
   });
 }
diff --git a/packages/map_runtime/test/battle_turn_presentation_test.dart b/packages/map_runtime/test/battle_turn_presentation_test.dart
index 6b0fcdc2..ee50883a 100644
--- a/packages/map_runtime/test/battle_turn_presentation_test.dart
+++ b/packages/map_runtime/test/battle_turn_presentation_test.dart
@@ -574,6 +574,112 @@ void main() {
       expect(steps[2].hpTo, equals(203));
     });
 
+    test(
+        'renders max potion use as a committed turn step before the enemy response',
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
+          itemKind: BattleBagHpHealItemKind.maxPotion,
+          targetLineupIndex: 0,
+          effect: BattleBagRestoreToFullHpHealEffect(),
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
+            itemKind: BattleBagHpHealItemKind.maxPotion,
+            side: BattleSideId.player,
+            targetLineupIndex: 0,
+            targetSpeciesId: 'sproutle',
+            hpBefore: 12,
+            hpAfter: 260,
+          ),
+        ],
+        timeline: <BattleTurnEvent>[
+          BattleTurnBagHpHealItemEvent(
+            BattleBagHpHealItemEvent(
+              itemKind: BattleBagHpHealItemKind.maxPotion,
+              side: BattleSideId.player,
+              targetLineupIndex: 0,
+              targetSpeciesId: 'sproutle',
+              hpBefore: 12,
+              hpAfter: 260,
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
+        equals('Joueur utilise Max Potion sur sproutle !'),
+      );
+      expect(steps[1].message, equals('sproutle récupère 248 PV.'));
+      expect(steps[1].hpFrom, equals(12));
+      expect(steps[1].hpTo, equals(260));
+      expect(steps[2].hpFrom, equals(260));
+      expect(steps[2].hpTo, equals(251));
+    });
+
     test('keeps status-like executions as message-only steps', () {
       final beforeSession = _session(
         player: _combatant(
diff --git a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
index 6548ea55..ed9beb47 100644
--- a/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
+++ b/packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
@@ -859,6 +859,124 @@ void main() {
       expect(game.gameStateSnapshot.bag.entries, isEmpty);
     });
 
+    test('battle BAG max potion use persists to PlayableMapGame state',
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
+        saveId: 'wild-flow-max-potion-save',
+        bag: Bag(
+          entries: <BagEntry>[
+            BagEntry(
+              itemId: 'max-potion',
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
+      final initialBattleMaxHp =
+          game.debugBattleSessionSnapshot!.state.player.maxHp;
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
+        isA<BattleActionBagHpHealItemUse>()
+            .having(
+              (action) => action.itemKind,
+              'itemKind',
+              equals(BattleBagHpHealItemKind.maxPotion),
+            )
+            .having(
+              (action) => action.effect,
+              'effect',
+              isA<BattleBagRestoreToFullHpHealEffect>(),
+            ),
+      );
+      expect(currentTurn.bagHpHealItemEvents, hasLength(1));
+      expect(
+        currentTurn.bagHpHealItemEvents.single.itemKind,
+        equals(BattleBagHpHealItemKind.maxPotion),
+      );
+      expect(
+        currentTurn.bagHpHealItemEvents.single.hpAfter,
+        equals(initialBattleMaxHp),
+      );
+      expect(
+        game.debugBattleSessionSnapshot!.state.player.currentHp,
+        lessThanOrEqualTo(initialBattleMaxHp),
+      );
+      expect(
+        game.gameStateSnapshot.party.members.first.currentHp,
+        equals(game.debugBattleSessionSnapshot!.state.player.currentHp),
+      );
+      expect(game.gameStateSnapshot.bag.entries, isEmpty);
+    });
+
     test('battle end keeps the overlay mounted until final narration finishes',
         () async {
       final manifest = await _writeProjectManifest(tempProjectRoot);
```
