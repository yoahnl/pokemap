# BE9 recadré — Field state réel + pseudoWeather réel + résiduels structurés

## 1. Résumé exécutif honnête

### Verdict honnête
BE9 recadré est réellement implémenté.

Le lot ouvre une vraie couche `field` battle locale et observable, strictement bornée à :
- `rain`
- `sandstorm`
- `trickRoom`
- une phase de fin de tour structurée qui consomme désormais à la fois les résiduels BE7 et les résiduels/durées de champ BE9

Le lot ne fait pas semblant d’ouvrir :
- `setTerrain`
- `setSideCondition`
- `setSlotCondition`
- hazards
- `Healing Wish`
- switch pipeline
- side/slot state riches

### Ce que j’ai réellement fait
- ajouté un vrai `BattleFieldState` local dans `map_battle` avec météo active, pseudoWeather actif, durées et événements de champ ;
- branché cet état dans `BattleSetup`, `BattleState`, la session battle et le résultat de tour ;
- fait consommer `rain` dans les dégâts (`water` boosté, `fire` réduit) ;
- fait consommer `sandstorm` comme résiduel réel de fin de tour avec immunité par type déjà supporté (`ground`, `rock`, `steel`) ;
- fait consommer `trickRoom` dans l’ordre d’action, à priorité égale uniquement ;
- restructuré la fin de tour en phase explicite : résiduels majeurs, résiduels météo, décrémentation/expiration de champ ;
- ouvert le bridge runtime uniquement pour `setWeather` (`raindance`, `sandstorm`) et `setPseudoWeather` (`trickroom`) ;
- gardé le rejet explicite des terrains/side/slot conditions ;
- ajouté des tests battle/runtime ciblés et des intégrations runtime -> battle pour pluie et Trick Room ;
- patché l’overlay runtime pour rendre les `fieldEvents` visibles et éviter un mensonge de surface ;
- resserré après review le bridge field pour refuser les faux moves de champ malformés avec `target: self`.

### Ce que je n’ai volontairement PAS fait
- aucun `BattleSideState` ;
- aucun `BattleSlotState` ;
- aucune ouverture hazards / Healing Wish ;
- aucun `setTerrain` ;
- aucune ability/item ;
- aucun switch pipeline ;
- aucune météo avancée ;
- aucun framework générique de hooks/events ;
- aucune modification de `map_core` ou `map_editor`.

### Vrai changement de code ou simple doc ?
C’est un vrai changement de code moteur et bridge, pas un lot documentaire.

## 2. Pré-gates exécutés + résultats

Pré-gates exécutés avant modification :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/application/runtime_pokemon_species_loader.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

Classification honnête :
- `git status --short`: vert comme lecture d’état, mais worktree déjà sale à cause du lot BE8 non committé.
- `git diff --stat`: vert comme lecture d’état.
- `git ls-files --others --exclude-standard`: vert comme lecture d’état.
- `packages/map_battle`: `dart test` vert.
- `packages/map_battle`: `dart analyze` vert.
- `packages/map_runtime`: suite de tests ciblée verte.
- `packages/map_runtime`: analyze ciblé vert.

Incident d’outillage pré-gates :
- Flutter a affiché un `startup lock` quand j’ai parallélisé `flutter test` et `flutter analyze`. Les deux commandes ont quand même terminé proprement en vert. Aucun rouge produit par le lot à ce stade.

## 3. État initial audité réel

Constats confirmés avant modification :
- `map_battle` ne portait aucun vrai `field state` observable ;
- ni météo, ni pseudoWeather, ni durée n’étaient consommés dans le moteur ;
- la fin de tour existait, mais restait structurée seulement pour les résiduels BE7, pas pour un vrai champ BE9 ;
- le bridge runtime refusait encore `setWeather`, `setPseudoWeather`, `setTerrain`, `setSideCondition`, `setSlotCondition` ;
- le canonique contenait bien ces familles d’effets dans `map_core`, et le converter Showdown savait déjà les produire ;
- le repo réel montrait bien `raindance` et `trickroom` comme IDs canoniques utilisés ;
- `sandstorm` existait côté battle typing/weather logique, mais je n’ai pas trouvé de fixture runtime déjà branchée au bridge pour ce move dans les surfaces relues ; j’ai donc ajouté une fixture de test locale au lieu d’élargir autre chose.

## 4. Problèmes confirmés / non confirmés

### Confirmés
- absence de `BattleFieldState` observable ;
- absence de consommation réelle de weather/pseudoWeather ;
- absence de phase de fin de tour structurée commune pour statuts + champ ;
- refus encore global de `setWeather` / `setPseudoWeather` côté bridge ;
- besoin d’une trace dédiée de champ, car `BattleMoveExecution` n’était pas la bonne place pour représenter pose/expiration/résiduel météo ;
- besoin d’un resserrage runtime après review : le bridge acceptait à tort les faux field moves malformés avec `target: self`.

### Non confirmés ou recadrés
- le prompt suggérait presque un besoin implicite de side/slot shells ; audit rejeté. Aucun `BattleSideState`/`BattleSlotState` n’était nécessaire ni honnête.
- la review séparée a remonté un “bug” sur le re-cast de Trick Room qui effacerait l’effet au lieu de le refresh. Je n’ai PAS retenu ce finding comme bug, car la sémantique canonique Pokémon/Showdown de Trick Room au re-cast est justement un toggle/clear, pas un refresh. J’ai ajouté un test explicite pour verrouiller cette décision et éviter tout flou.

## 5. Cause racine réelle

La cause racine n’était pas “le runtime bridge trop pauvre”, mais l’absence d’un vrai état de champ battle consommé par le moteur.

Tant que `map_battle` ne portait pas un `field state` local :
- le bridge devait refuser les moves météo / room ;
- la météo restait décorative ;
- Trick Room n’avait aucune couche d’intégration honnête avec l’ordre BE3 ;
- la fin de tour restait trop ponctuelle pour absorber proprement météo + expiration.

## 6. Décisions retenues / rejetées

### Retenues
- créer `packages/map_battle/lib/src/battle_field.dart` comme petit contrat local dédié ;
- porter `BattleFieldState` directement dans `BattleSetup` puis `BattleState` ;
- tracer les événements de champ dans `BattleTurnResult.fieldEvents`, séparés de `statusEvents` et `volatileEvents` ;
- ne supporter que `rain`, `sandstorm`, `trickRoom` ;
- décrémenter les durées en fin de tour, y compris le tour où l’effet a été posé ; une pose à 5 finit donc le tour à 4 ;
- faire consommer Trick Room uniquement au niveau de la comparaison de vitesse à priorité égale ;
- laisser priorité puis tie-break déterministe inchangés ;
- restructurer la fin de tour dans un petit helper local au lieu d’ouvrir un bus d’événements ;
- autoriser très étroitement certains `structuredPartial` pour `trick_room` uniquement via allowlist de `unsupportedReasons` ;
- resserrer après review le bridge field pour n’accepter que `target: all` sur le sous-ensemble BE9 réellement seedé.

### Rejetées
- créer un `BattleSideState` ou `BattleSlotState` vides ;
- ouvrir terrains ;
- ouvrir hazards / Healing Wish ;
- ouvrir tous les `structuredPartial` ;
- faire vivre la météo/pseudoWeather comme détail privé de `BattleSession` ;
- gonfler `BattleMoveExecution` avec des booléens de champ ;
- accepter `target: self` pour les moves de champ “par tolérance”.

## 7. Critique explicite du prompt

### Ce qui était juste
- le recadrage away from switch/side/slot/hazards était correct et nécessaire ;
- demander un vrai `field state` observable plutôt qu’un détail privé était juste ;
- demander une vraie phase de fin de tour structurée était juste ;
- demander un bridge strict et des refus explicites était juste.

### Ce qui était discutable
- le prompt pouvait faire croire que `sandstorm` existait déjà forcément comme move seedé dans les fixtures runtime. Ce n’était pas confirmé par l’audit ; j’ai ajouté une fixture locale de test au lieu de sur-promettre un pipeline existant.
- la demande “continuer à rejeter explicitement terrains/side/slot” était juste sur le fond, mais trop rigide si on l’interprète comme “même code d’erreur exact”. Dans le code réel, certains cas sont rejetés plus tôt par la forme de target ; c’est toujours honnête, et j’ai gardé les tests tolérants à cette réalité.

### Ce qui aurait été dangereux si suivi aveuglément
- créer des shells side/slot vides “pour préparer BE10+” ;
- ouvrir globalement tous les `structuredPartial` pour faire passer Trick Room ;
- toucher `map_core` ou `map_editor` alors que le vrai besoin était battle/runtime local.

### Ce que j’ai recadré
- pas de `BattleSideState` / `BattleSlotState` ;
- allowlist étroite de `structuredPartial` uniquement pour les vieux catalogues de `trick_room` ;
- `target: all` seulement pour les field moves BE9 réellement supportés ;
- overlay patch minimal uniquement pour rendre les `fieldEvents` visibles.

### Pourquoi ce recadrage est meilleur pour ce repo réel
Parce qu’il ouvre une vraie couche moteur consommée immédiatement, sans structure morte ni faux support sur des mécaniques qui dépendent encore du switch pipeline.

## 8. Périmètre inclus / exclu

### Inclus
- `BattleFieldState` ;
- `BattleFieldEvent` ;
- weather `rain` et `sandstorm` ;
- pseudoWeather `trickRoom` ;
- fin de tour structurée ;
- ouverture bridge `setWeather`/`setPseudoWeather` sur sous-ensemble BE9 ;
- overlay minimal pour afficher les événements de champ ;
- tests battle/runtime/intégration BE9.

### Exclus
- terrains ;
- side conditions ;
- slot conditions ;
- hazards ;
- Healing Wish ;
- switch pipeline ;
- side/slot state riches ;
- doubles ;
- hooks génériques ;
- event bus ;
- `map_core` ;
- `map_editor`.

## 9. Liste exacte des fichiers modifiés / créés / supprimés

### Modifiés dans ce lot
- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/test/battle_session_test.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

### Créés dans ce lot
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/test/battle_field_test.dart`
- `reports/phase-battle-be9-field-state-report.md`

### Non touchés par ce lot malgré worktree sale
Ces fichiers apparaissaient déjà sales ou non suivis avant ce lot et je ne les ai pas modifiés pour BE9 :
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/test/battle_volatiles_test.dart`
- `reports/phase-battle-be8-volatiles-protect-recharge-charge-report.md`

### Supprimés
- aucun

## 10. Justification fichier par fichier

- `packages/map_battle/lib/src/battle_field.dart` : nouveau contrat local BE9 pour weather/pseudoWeather/durées/field events.
- `packages/map_battle/lib/map_battle.dart` : export public du nouveau contrat battle.
- `packages/map_battle/lib/src/battle_move.dart` : transport minimal de `weatherEffect`, `pseudoWeatherEffect` et `BattleMoveTarget.field`.
- `packages/map_battle/lib/src/battle_setup.dart` : transport de `fieldState` et enrichissement de `BattleMoveData`.
- `packages/map_battle/lib/src/battle_state.dart` : ajout de `field` dans l’état battle observable.
- `packages/map_battle/lib/src/battle_resolution.dart` : ajout de `fieldEvents` dans `BattleTurnResult`.
- `packages/map_battle/lib/src/battle_session.dart` : vraie consommation moteur BE9 (scheduler, damage, end-of-turn, field application, expiration, traces).
- `packages/map_battle/test/battle_field_test.dart` : preuves ciblées BE9.
- `packages/map_battle/test/battle_session_test.dart` : non-régression du transport de contrat battle enrichi jusqu’à BE9.
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart` : ouverture stricte de `setWeather`/`setPseudoWeather`, refus explicites maintenus, allowlist étroite `structuredPartial`, resserrage `target: all` après review.
- `packages/map_runtime/test/runtime_battle_move_bridge_test.dart` : preuves bridge positives/négatives du sous-ensemble BE9.
- `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart` : preuve que le builder ne reperd pas les nouveaux champs BE9.
- `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart` : intégrations runtime -> battle pour pluie et Trick Room.
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` : patch minimal pour rendre les `fieldEvents` visibles et éviter un mensonge de surface.

## 11. Commandes réellement exécutées

### Lecture / audit
- `git status --short`
- `git diff --stat`
- `git ls-files --others --exclude-standard`
- `rg -n "protect|Protect|requireRecharge|chargeThenStrike|breakProtect|applyVolatileStatus|volatile|hyper_beam|hyper beam|solar_beam|solar beam|feint|detect" packages`
- multiples `sed -n ...` ciblés sur les fichiers battle/runtime/tests/core/editor/report listés dans le prompt
- `rg -n "BattleState\(|BattleTurnResult\(|BattleMoveTarget\.field|BattleMoveTarget\." packages/map_battle packages/map_runtime`
- autres `rg` ciblés sur `setWeather`, `setPseudoWeather`, `setTerrain`, `setSideCondition`, `setSlotCondition`, `structuredPartial`, `rain_dance`, `sandstorm`, `trick_room`

### Pré-gates avant code
- toutes les commandes de la section 2

### Validation intermédiaire / ciblée
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_field_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart test test/battle_field_test.dart test/battle_session_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub ...`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart`

### Format
- `cd packages/map_battle && /opt/homebrew/bin/dart format lib/map_battle.dart lib/src/battle_field.dart lib/src/battle_move.dart lib/src/battle_setup.dart lib/src/battle_state.dart lib/src/battle_resolution.dart lib/src/battle_session.dart test/battle_field_test.dart test/battle_session_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/dart format lib/src/application/runtime_battle_move_bridge.dart lib/src/presentation/flame/battle_overlay_component.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/dart format test/runtime_battle_move_bridge_test.dart`
- `cd packages/map_battle && /opt/homebrew/bin/dart format test/battle_field_test.dart`

### Validation finale
- `cd packages/map_battle && /opt/homebrew/bin/dart analyze`
- `cd packages/map_battle && /opt/homebrew/bin/dart test`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/application/runtime_battle_move_bridge.dart lib/src/application/runtime_battle_combatant_seed_builder.dart lib/src/application/runtime_battle_setup_mapper.dart lib/src/presentation/flame/battle_overlay_component.dart lib/src/application/runtime_pokemon_species_loader.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`
- `cd packages/map_runtime && /opt/homebrew/bin/flutter test test/runtime_move_catalog_loader_test.dart test/runtime_pokemon_species_loader_test.dart test/runtime_pokemon_learnset_loader_test.dart test/runtime_battle_move_bridge_test.dart test/runtime_battle_combatant_seed_builder_test.dart test/runtime_battle_setup_mapper_test.dart test/runtime_battle_outcome_apply_test.dart test/wild_battle_end_to_end_flow_test.dart test/playable_map_game_whiteout_lite_test.dart`

### Sub-agents
- spawn audit/design explorer `Newton` (`019d96c6-80dc-7083-9901-3cd105a00a92`)
- spawn reviewer `Harvey` (`019d96dd-4b66-7b31-bcd4-9cc859a21ba6`)
- spawn reviewer `Faraday` (`019d96df-97bc-7413-8c5f-8a882290cd71`)
- waits/closures associées

## 12. Résultats réels de format / analyze / tests

### Format
- `packages/map_battle`: vert
- `packages/map_runtime`: vert

### Analyze
- `packages/map_battle`: vert (`No issues found!`)
- `packages/map_runtime` ciblé : vert (`No issues found!`)

### Tests
- `packages/map_battle`: vert (`dart test` complet)
- `packages/map_runtime`: vert (suite ciblée complète du prompt)

## 13. Incidents rencontrés

- worktree déjà sale avant BE9 à cause du lot BE8 non committé ;
- `flutter analyze` / `flutter test` parallélisés ont brièvement affiché `Waiting for another flutter command to release the startup lock...`, sans échec ;
- deux rouges intermédiaires de tests runtime sur `setTerrain` et `setSideCondition` venaient d’une hypothèse de test trop précise sur le code d’erreur (`unsupported_effect_kind`), alors que le bridge peut honnêtement rejeter plus tôt par la forme de target ; j’ai corrigé les tests, pas le moteur ;
- reviewer `Harvey` a remonté deux points :
  - un point valide retenu (`target: self` accepté à tort pour les field moves) ;
  - un point rejeté après vérification (`Trick Room` recast “devrait refresh”), car le toggle/clear est justement la sémantique canonique retenue ;
- reviewer `Faraday` n’a pas fourni de payload exploitable avant fermeture.

## 14. État git utile

### `git status --short`
```text
 M packages/map_battle/lib/map_battle.dart
 M packages/map_battle/lib/src/battle_action.dart
 M packages/map_battle/lib/src/battle_move.dart
 M packages/map_battle/lib/src/battle_resolution.dart
 M packages/map_battle/lib/src/battle_session.dart
 M packages/map_battle/lib/src/battle_setup.dart
 M packages/map_battle/lib/src/battle_state.dart
 M packages/map_battle/test/battle_session_test.dart
 M packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart
 M packages/map_runtime/test/runtime_battle_move_bridge_test.dart
 M packages/map_runtime/test/runtime_battle_setup_mapper_test.dart
?? packages/map_battle/lib/src/battle_field.dart
?? packages/map_battle/lib/src/battle_volatile.dart
?? packages/map_battle/test/battle_field_test.dart
?? packages/map_battle/test/battle_volatiles_test.dart
?? reports/phase-battle-be8-volatiles-protect-recharge-charge-report.md
?? reports/phase-battle-be9-field-state-report.md
```

### `git diff --stat`
```text
 packages/map_battle/lib/map_battle.dart            |   2 +
 packages/map_battle/lib/src/battle_action.dart     |  28 +
 packages/map_battle/lib/src/battle_move.dart       |  85 ++
 packages/map_battle/lib/src/battle_resolution.dart |  29 +-
 packages/map_battle/lib/src/battle_session.dart    | 851 ++++++++++++++++++++-
 packages/map_battle/lib/src/battle_setup.dart      |  70 ++
 packages/map_battle/lib/src/battle_state.dart      |  53 ++
 packages/map_battle/test/battle_session_test.dart  | 154 +++-
 .../application/runtime_battle_move_bridge.dart    | 453 ++++++++++-
 .../flame/battle_overlay_component.dart            |  78 +-
 ...runtime_battle_combatant_seed_builder_test.dart | 160 ++++
 .../test/runtime_battle_move_bridge_test.dart      | 514 ++++++++++++-
 .../test/runtime_battle_setup_mapper_test.dart     | 285 ++++++-
 13 files changed, 2663 insertions(+), 99 deletions(-)
```

### `git ls-files --others --exclude-standard`
```text
packages/map_battle/lib/src/battle_field.dart
packages/map_battle/lib/src/battle_volatile.dart
packages/map_battle/test/battle_field_test.dart
packages/map_battle/test/battle_volatiles_test.dart
reports/phase-battle-be8-volatiles-protect-recharge-charge-report.md
reports/phase-battle-be9-field-state-report.md
```

Note honnête : ces trois commandes reflètent le worktree global, pas un diff isolé BE9. Le worktree contenait déjà des changements BE8 avant ce lot.

## 15. Checklist finale

- [x] j’ai audité le code réel avant de coder
- [x] j’ai challengé le prompt
- [x] je n’ai pas accepté le prompt aveuglément
- [x] j’ai exécuté les pré-gates
- [x] je n’ai pas touché `map_core`
- [x] je n’ai pas touché `map_editor`
- [x] je n’ai pas créé de stack parallèle
- [x] j’ai introduit un vrai `field state` battle observable
- [x] `rain`, `sandstorm`, `trickRoom` sont réellement portés et consommés
- [x] `setWeather` et `setPseudoWeather` sont supportés honnêtement sur le sous-ensemble BE9
- [x] `setTerrain`, `setSideCondition`, `setSlotCondition` et le reste hors scope restent refusés explicitement
- [x] la fin de tour structurée existe réellement
- [x] la trace du tour ne ment pas sur les événements de champ
- [x] je n’ai pas rouvert side/slot/switch/hazards en douce
- [x] j’ai ajouté des tests ciblés utiles
- [x] j’ai exécuté format
- [x] j’ai exécuté analyze
- [x] j’ai exécuté les tests utiles
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai utilisé une review séparée réelle
- [x] j’ai intégré les remarques valides
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report est honnête
- [x] le report contient le contenu complet des fichiers touchés

## 16. Retour du sub-agent d’audit/design

Sub-agent utilisé : `Newton` (`019d96c6-80dc-7083-9901-3cd105a00a92`).

Apports retenus :
- confirmation que `setWeather`, `setPseudoWeather`, `setTerrain`, `setSideCondition`, `setSlotCondition` existent déjà dans le canonique ;
- confirmation que `raindance` et `trickroom` sont bien les IDs canoniques utilisés dans les seeds/tests consultés ;
- confirmation que le vrai seam honnête était un `BattleFieldState` local, pas un shell side/slot ;
- recommandation juste de refuser explicitement hazards / Healing Wish / side/slot riches.

Apports rejetés :
- aucun finding majeur rejeté côté audit/design.

## 17. Retour du reviewer séparé

Reviewer principal utilisé : `Harvey` (`019d96dd-4b66-7b31-bcd4-9cc859a21ba6`).

Retour exploitable :
- finding retenu : le bridge field acceptait aussi `target: self`, ce qui élargissait inutilement le contrat BE9 ; corrigé ;
- finding rejeté : la suggestion de refresh Trick Room au re-cast. Après vérification, le toggle/clear est la sémantique canonique retenue ; j’ai ajouté un test qui verrouille explicitement cette décision.

Reviewer secondaire : `Faraday` (`019d96df-97bc-7413-8c5f-8a882290cd71`).
- pas de payload exploitable avant fermeture ;
- rien d’inventé dans ce report.

## 18. Corrections appliquées après review

- resserrage de `RuntimeBattleMoveBridge` pour n’accepter les field moves BE9 qu’avec `target: all` ;
- ajout d’un test négatif runtime pour rejeter un faux field move `target: self` ;
- ajout d’un test battle qui verrouille explicitement le re-cast de Trick Room comme toggle/clear.

## 19. Autocritique finale

Le lot est petit et honnête, mais il a deux limites assumées :
- le bridge refuse encore certains terrains/side/slot d’abord via la forme de target, puis seulement parfois via la famille d’effet. C’est honnête, mais pas la granularité d’erreur la plus fine possible.
- l’overlay runtime affiche maintenant les `fieldEvents`, mais il reste par ailleurs plus pauvre que l’état battle complet (par exemple, tout l’historique status/volatile n’est pas uniformisé dans une UI riche). Je n’ai pas élargi ce chantier hors scope.

Autre point honnête :
- le worktree était déjà sale à cause de BE8, ce qui rend le `git diff --stat` global plus bruyant que le vrai delta BE9. Le report le dit explicitement au lieu de faire semblant d’avoir un diff propre isolé.

## 20. Annexe — contenu complet de tous les fichiers texte touchés

Le report s’exclut lui-même de cette annexe pour éviter la récursion infinie.

### `packages/map_battle/lib/map_battle.dart`

~~~~dart
/// Battle engine for Pokémon-like RPG combat.
///
/// Pure Dart package, independent of Flutter/Flame.
/// Deterministic, testable, and minimal.
///
/// ## Usage
///
/// ```dart
/// // 1. Create setup
/// final setup = BattleSetup(
///   playerPokemon: BattleCombatantData(
///     speciesId: 'pikachu',
///     level: 5,
///     maxHp: 20,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   enemyPokemon: BattleCombatantData(
///     speciesId: 'lapras',
///     level: 5,
///     maxHp: 25,
///     stats: const BattleStatsSnapshot(
///       attack: 10,
///       defense: 10,
///       specialAttack: 10,
///       specialDefense: 10,
///       speed: 10,
///     ),
///     moves: [BattleMoveData(id: 'tackle', name: 'Charge', power: 5)],
///   ),
///   isTrainerBattle: true,
///   trainerId: 'gym_leader_1',
/// );
///
/// // 2. Create session
/// final session = createBattleSession(setup);
///
/// // 3. Get available choices
/// final choices = session.getAvailableChoices();
///
/// // 4. Apply choice
/// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
///
/// // 5. Check if finished
/// if (newSession.state.isFinished) {
///   final outcome = newSession.state.outcome!;
///   if (outcome.isVictory) {
///     // Mark trainer as defeated
///   }
/// }
/// ```
library map_battle;

export 'src/battle_setup.dart';
export 'src/battle_session.dart';
export 'src/battle_state.dart';
export 'src/battle_field.dart';
export 'src/battle_status.dart';
export 'src/battle_volatile.dart';
export 'src/battle_stats.dart';
export 'src/battle_typing.dart';
export 'src/battle_type_chart.dart';
export 'src/battle_rng.dart';
export 'src/battle_action.dart';
export 'src/battle_move.dart';
export 'src/battle_resolution.dart';

~~~~

### `packages/map_battle/lib/src/battle_field.dart`

~~~~dart
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
        target = null,
        damage = null;

  const BattleFieldEvent.weatherResidualDamage({
    required this.weather,
    required this.target,
    required this.damage,
  })  : kind = BattleFieldEventKind.weatherResidualDamage,
        pseudoWeather = null,
        sourceMoveId = null;

  const BattleFieldEvent.weatherExpired({
    required this.weather,
  })  : kind = BattleFieldEventKind.weatherExpired,
        pseudoWeather = null,
        sourceMoveId = null,
        target = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherSet({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherSet,
        weather = null,
        target = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherCleared({
    required this.pseudoWeather,
    required this.sourceMoveId,
  })  : kind = BattleFieldEventKind.pseudoWeatherCleared,
        weather = null,
        target = null,
        damage = null;

  const BattleFieldEvent.pseudoWeatherExpired({
    required this.pseudoWeather,
  })  : kind = BattleFieldEventKind.pseudoWeatherExpired,
        weather = null,
        sourceMoveId = null,
        target = null,
        damage = null;

  final BattleFieldEventKind kind;
  final BattleWeatherId? weather;
  final BattlePseudoWeatherId? pseudoWeather;
  final String? sourceMoveId;
  final String? target;
  final int? damage;
}

~~~~

### `packages/map_battle/lib/src/battle_move.dart`

~~~~dart
import 'battle_field.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';

/// Catégorie battle minimale d'une attaque.
///
/// M8 puis BE5 n'ouvrent toujours pas un système de typing complet, mais le
/// bridge runtime -> battle doit au moins distinguer :
/// - les attaques physiques ;
/// - les attaques spéciales ;
/// - les attaques de statut.
///
/// Cette information suffit pour donner un vrai effet battle au petit
/// sous-ensemble `modifyStats` retenu dans ce lot.
enum BattleMoveCategory {
  physical,
  special,
  status,
}

/// Cible battle minimale explicitement transportée par le bridge runtime.
///
/// BE1 ne crée pas un système de ciblage complet façon Showdown.
/// On transporte seulement ce qui est déjà honnête dans le moteur actuel :
/// - `self` pour les moves explicitement auto-ciblés ;
/// - `opponent` pour les moves qui, en 1v1 simple actif, ciblent l'adversaire ;
/// - `field` pour les moves BE9 qui posent une météo ou un pseudoWeather ;
/// - `unspecified` comme compatibilité pour les anciens call sites/tests qui
///   construisaient encore des `BattleMoveData` pauvres à la main.
///
/// Important :
/// - `unspecified` n'est pas une nouvelle sémantique battle ;
/// - c'est un garde-fou de compatibilité pour éviter d'inventer une cible
///   mensongère sur les anciens setups locaux ;
/// - le bridge runtime BE1, lui, doit toujours fournir une cible explicite.
enum BattleMoveTarget {
  unspecified,
  opponent,
  self,
  field,
}

/// Contrat minimal de précision réellement exécutable par `map_battle`.
///
/// BE4 n'importe pas `PokemonMoveAccuracy` depuis `map_core` :
/// - `map_battle` doit rester pur et indépendant du modèle projet ;
/// - le bridge runtime traduit donc vers ce petit contrat local ;
/// - on ne transporte que ce que le moteur sait réellement consommer.
///
/// Frontière volontaire :
/// - `alwaysHits` pour les moves qui bypassent le hit check ;
/// - `percent` pour un pourcentage entier simple ;
/// - pas d'evasion/accuracy stages ;
/// - pas d'autres variantes exotériques.
///
/// Note BE4 :
/// - `percent(100)` reste distinct de `alwaysHits` dans la donnée transportée ;
/// - mais le moteur actuel le résout quand même de façon déterministe, faute
///   de modificateurs accuracy/evasion dans ce lot.
enum BattleMoveAccuracyKind {
  alwaysHits,
  percent,
}

/// Représentation battle minimale de la précision.
///
/// Décision de BE4 :
/// - ce type vit au plus près de `BattleMove` parce qu'il n'a de sens que
///   pour le contrat move battle ;
/// - il reste petit, explicite et testable ;
/// - il n'ouvre ni une taxonomie canonique parallèle, ni une logique moteur
///   générique hors de proportion.
class BattleMoveAccuracy {
  const BattleMoveAccuracy.alwaysHits()
      : kind = BattleMoveAccuracyKind.alwaysHits,
        value = 100;

  const BattleMoveAccuracy.percent({
    required this.value,
  })  : assert(value >= 1 && value <= 100),
        kind = BattleMoveAccuracyKind.percent;

  final BattleMoveAccuracyKind kind;
  final int value;

  bool get isAlwaysHits => kind == BattleMoveAccuracyKind.alwaysHits;
}

/// Identifiant de stat exploitable par le moteur battle MVP enrichi.
///
/// Décision volontairement bornée pour M8 puis BE3 :
/// - on ne porte que les stats déjà utiles à un effet battle réel ;
/// - BE3 ouvre `speed` parce qu'elle devient enfin consommée pour l'ordre
///   d'action minimal honnête ;
/// - on n'ouvre toujours pas accuracy / evasion, car cela rouvrirait la
///   précision réelle et d'autres mécaniques hors scope ;
/// - le bridge runtime continue donc de refuser explicitement ces autres cas.
enum BattleStatId {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Changement d'étage de stat appliqué pendant le combat.
///
/// Ce type est petit mais typé :
/// - il évite de faire circuler des `Map<String, int>` peu robustes ;
/// - il garde `BattleMoveData` et `BattleMove` lisibles ;
/// - il permet au moteur MVP d'appliquer un vrai effet non-dégât.
class BattleStatStageChange {
  const BattleStatStageChange({
    required this.stat,
    required this.stages,
  });

  final BattleStatId stat;
  final int stages;
}

/// Attaque utilisée pendant un combat.
///
/// Ce modèle représente une attaque disponible pour un combattant.
/// Il est utilisé pendant le combat, contrairement à [BattleMoveData]
/// qui est utilisé uniquement pour la configuration initiale.
///
/// Mini-fix BE6-2 :
/// - cette classe devient volontairement `final` ;
/// - ce n'est pas un point d'extension du moteur, mais un contrat de donnée ;
/// - le mini-fix précédent avait amélioré la robustesse locale, tout en
///   laissant un bypass trivial par héritage/override dans les tests ;
/// - on ferme donc ce trou au niveau langage au lieu de continuer à écrire
///   des preuves artificielles basées sur des sous-classes malformées.
final class BattleMove {
  /// Crée une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté et désormais consommé pour STAB /
  ///   type chart dans le petit sous-ensemble honnête BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision minimale réellement consommée par BE4.
  /// [pp] - Le PP max du move.
  /// [currentPp] - Le PP courant dans l'état battle.
  /// [priority] - Priorité canonique réellement consommée par BE3 pour
  ///   l'ordre d'action 1v1 minimal.
  /// [critRatio] - Ratio critique minimal désormais consommé par BE6.
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal réellement
  ///   supporté par BE7 pour `par`, `brn`, `psn`, `tox`.
  /// [selfVolatileStatus] - Volatile auto-appliqué dans le petit sous-ensemble
  ///   BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [breaksProtect] - Permet au move de bypasser une protection active BE8.
  /// [requiresRecharge] - Demande un tour de recharge honnête au lanceur après
  ///   une exécution réussie.
  /// [chargeThenStrikeEffect] - Porte le petit contrat local d'un move qui
  ///   charge un tour puis frappe le tour suivant sans repayer les PP.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  ///
  /// M8 puis BE1 choisissent volontairement de n'embarquer ici qu'un petit
  /// sous-ensemble :
  /// - dégâts standards ;
  /// - modifications déterministes de stats ;
  /// - transport honnête de quelques dimensions structurantes (`type`,
  ///   `target`, `pp`) pour arrêter leur perte silencieuse au handoff ;
  /// - puis, en BE3, transport et consommation réelle de `priority` pour
  ///   sortir du mensonge "joueur puis ennemi" ;
  /// - puis, en BE4, un vrai hit pipeline minimal avec précision et PP ;
  /// - puis, en BE6, un crit minimal honnête via `critRatio` ;
  /// - puis, en BE7, un petit sous-ensemble `applyStatus` réellement
  ///   exécutable sans ouvrir un système générique de statuts ;
  /// - puis, en BE8, quelques volatiles utiles strictement bornés à
  ///   `Protect`, `requireRecharge`, `chargeThenStrike` et `breakProtect` ;
  /// - puis, en BE9, un tout petit seam de champ pour `rain`, `sandstorm`
  ///   et `trickRoom`, sans ouvrir side/slot/terrain ;
  /// - toujours aucun status non volatil, aucun scheduler générique.
  const BattleMove({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    int? currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  })  : assert(
          critRatio >= 1,
          'BattleMove critRatio must be >= 1.',
        ),
        _critRatio = critRatio,
        currentPp = currentPp ?? pp;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Pour ce MVP enrichi :
  /// - les dégâts standards partent toujours de `power` ;
  /// - des multiplicateurs d'étages de stats peuvent maintenant s'ajouter ;
  /// - un move de statut garde généralement `power == 0`.
  final int power;

  /// Type canonique transporté jusqu'au moteur battle.
  ///
  /// Historique utile :
  /// - BE1 arrête d'abord sa perte silencieuse au bridge ;
  /// - BE5 commence ensuite à le consommer réellement pour STAB,
  ///   effectiveness et immunités ;
  /// - on reste malgré tout très loin d'un système de type Pokémon complet
  ///   (pas d'abilities, pas de Tera, pas d'effets spéciaux de move).
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Compatibilité ascendante :
  /// - les anciens tests/call sites n'avaient que `power` ;
  /// - on garde donc ce champ optionnel ;
  /// - si absent, on déduit une catégorie minimale historique.
  final BattleMoveCategory? category;

  /// Cible battle minimale transportée jusqu'au moteur.
  ///
  /// Le moteur MVP ne l'exécute pas encore activement dans sa résolution :
  /// - le combat reste 1v1 simple actif ;
  /// - mais BE1 arrête au moins de perdre cette information au handoff ;
  /// - les targets incompatibles avec ce petit contrat sont refusés plus tôt
  ///   par le bridge runtime.
  ///
  /// BE9 ajoute `field` pour les moves qui posent une météo ou `Trick Room` :
  /// - ces moves ne visent ni réellement `self`, ni réellement `opponent` ;
  /// - les marquer `unspecified` reperdrait une intention désormais consommée
  ///   par le moteur ;
  /// - on garde malgré tout un targeting battle très petit.
  final BattleMoveTarget target;

  /// Précision réellement consommée par le moteur battle.
  ///
  /// BE4 garde ici un contrat petit mais honnête :
  /// - `alwaysHits` bypasse le hit check ;
  /// - `percent` déclenche un check simple sur 1..100 pour les valeurs
  ///   réellement non triviales ;
  /// - `percent(100)` reste déterministe dans le moteur actuel, car BE4
  ///   n'ouvre toujours ni accuracy stages, ni evasion ;
  /// - pas d'autres couches de précision, pas d'evasion, pas de modificateurs.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move dans l'état battle.
  ///
  /// `pp` reste le contrat de capacité max du move.
  /// L'état courant vit dans [currentPp].
  ///
  /// Compatibilité volontairement bornée :
  /// - le runtime principal fournit déjà le PP canonique réel ;
  /// - les anciens call sites battle directs omettaient souvent ce champ ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration parasite de tous les setups battle locaux.
  final int pp;

  /// PP courant du move dans l'état battle.
  ///
  /// BE4 ouvre enfin cette donnée parce que :
  /// - les PP cessent d'être décoratifs ;
  /// - le moteur doit pouvoir filtrer les moves inutilisables ;
  /// - un miss consomme quand même 1 PP de façon honnête.
  final int currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE3 consomme enfin cette donnée pour fermer le trou :
  /// - priorité d'abord ;
  /// - puis vitesse effective ;
  /// - puis tie-break déterministe explicite.
  ///
  /// On garde un défaut à `0` pour préserver les anciens call sites/tests qui
  /// construisent encore des moves battle pauvres à la main.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 choisit ici le plus petit contrat utile :
  /// - on transporte l'entier canonique déjà présent côté runtime ;
  /// - le moteur l'interprète via une table explicite de chances ;
  /// - on n'ouvre pas pour autant les règles Pokémon avancées liées aux crits
  ///   (abilities, items, Focus Energy, Lucky Chant, ignore stages, etc.).
  ///
  /// Valeur neutre :
  /// - `1` signifie le ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - ce contrat public reste `const`, donc le garde-fou local le plus petit
  ///   et le plus cohérent ici reste une assertion ;
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le bypass trivial par override externe disparaît ;
  /// - on ajoute quand même aussi une validation runtime au getter, parce
  ///   qu'un objet battle incohérent peut encore émerger d'un futur mauvais
  ///   refactor interne ou d'un état construit dans cette même librairie ;
  /// - le moteur garde enfin une dernière validation défensive plus loin :
  ///   cette garde n'est plus la preuve principale du contrat public, mais
  ///   une défense en profondeur.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError('BattleMove critRatio must be >= 1; got $_critRatio.');
    }
    return _critRatio;
  }

  /// Effet battle minimal de statut majeur transporté par le bridge runtime.
  ///
  /// BE7 garde ce contrat volontairement petit :
  /// - un seul effet de statut majeur par move ;
  /// - pas de payload canonique complet ;
  /// - pas de support des volatiles ;
  /// - pas de targeting générique, car le bridge ne laisse déjà passer que le
  ///   scope `target` honnêtement exécutable aujourd'hui.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par ce move dans le sous-ensemble BE8.
  ///
  /// Ce champ reste volontairement étroit :
  /// - `protect` seulement ;
  /// - pas de confusion, pas de semi-invulnérabilité, pas de framework
  ///   générique de volatiles.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  ///
  /// Le move porte seulement l'intention de pose :
  /// - la durée et l'état actif vivent dans `BattleFieldState` ;
  /// - `rain` et `sandstorm` sont les seuls IDs réellement supportés ;
  /// - pas de météo avancée, pas d'abilities, pas d'items.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  ///
  /// Même frontière que pour [weatherEffect] :
  /// - `trickRoom` seulement ;
  /// - aucun système générique de rooms ;
  /// - la durée et l'expiration vivent dans `BattleFieldState`.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// true si ce move peut percer une protection active BE8.
  ///
  /// Le booléen reste plus honnête qu'une abstraction générique :
  /// - il documente un unique besoin réel du lot ;
  /// - il évite d'ouvrir une taxonomie entière de "modificateurs de défense"
  ///   alors que seul `breakProtect` est réellement exécutable ici.
  final bool breaksProtect;

  /// true si ce move impose ensuite un tour de recharge au lanceur.
  ///
  /// BE8 garde une sémantique locale explicite :
  /// - le move réussi ;
  /// - le combattant marque ensuite un état `mustRecharge` ;
  /// - le tour suivant est perdu honnêtement, puis l'état est nettoyé.
  final bool requiresRecharge;

  /// Petit payload d'un move à charge sur deux tours.
  ///
  /// Si non-null :
  /// - le premier tour ne fait que charger ;
  /// - le second réutilise ce move sans redépenser les PP ;
  /// - le moteur n'ouvre ni raccourci météo, ni Power Herb, ni autres cas
  ///   spéciaux hors scope.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;

  /// true si le move peut encore être tenté honnêtement.
  ///
  /// BE4 n'ouvre toujours pas Struggle :
  /// - un move à `currentPp == 0` n'est donc plus utilisable ;
  /// - `getAvailableChoices()` doit le filtrer ;
  /// - un forçage direct du moteur doit être refusé explicitement.
  bool get hasUsablePp => currentPp > 0;

  /// Catégorie réellement utilisée par le moteur.
  ///
  /// Le bridge runtime fournit maintenant cette info explicitement, mais ce
  /// getter garde une compatibilité honnête avec les anciens setups pauvres :
  /// - `power <= 0` => move de statut ;
  /// - sinon, fallback historique sur "physical".
  BattleMoveCategory get resolvedCategory {
    if (category != null) {
      return category!;
    }
    if (power <= 0) {
      return BattleMoveCategory.status;
    }
    return BattleMoveCategory.physical;
  }

  /// Retourne une copie avec 1 PP consommé.
  ///
  /// Le décrément reste local au move, ce qui évite de réinventer un
  /// conteneur battle parallèle juste pour les PP.
  BattleMove withConsumedPp() {
    return BattleMove(
      id: id,
      name: name,
      power: power,
      type: type,
      category: category,
      target: target,
      accuracy: accuracy,
      pp: pp,
      currentPp: currentPp > 0 ? currentPp - 1 : 0,
      priority: priority,
      critRatio: critRatio,
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
    );
  }
}

~~~~

### `packages/map_battle/lib/src/battle_resolution.dart`

~~~~dart
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_state.dart';
import 'battle_status.dart';
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
  const BattleTurnResult({
    required this.playerAction,
    required this.enemyAction,
    required this.executions,
    this.statusEvents = const <BattleStatusEvent>[],
    this.volatileEvents = const <BattleVolatileEvent>[],
    this.fieldEvents = const <BattleFieldEvent>[],
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
}

/// Exécution d'une attaque.
///
/// Représente une attaque qui a été exécutée avec ses effets.
class BattleMoveExecution {
  /// Crée une exécution d'attaque.
  ///
  /// [attacker] - L'identifiant de l'attaquant ("player" ou "enemy").
  /// [move] - L'attaque utilisée.
  /// [target] - L'identifiant de la cible ("player" ou "enemy").
  /// [damage] - Les dégâts infligés.
  /// [didHit] - true si le move a réellement touché.
  /// [didCrit] - true si le move a réellement déclenché un critique.
  /// [criticalMultiplier] - Multiplicateur critique réellement appliqué.
  /// [stabMultiplier] - Multiplicateur STAB réellement consommé pour ce hit.
  /// [typeEffectivenessMultiplier] - Multiplicateur de type réellement appliqué.
  const BattleMoveExecution({
    required this.attacker,
    required this.move,
    required this.target,
    required this.damage,
    required this.didHit,
    this.didCrit = false,
    this.criticalMultiplier = 1.0,
    this.stabMultiplier = 1.0,
    this.typeEffectivenessMultiplier = 1.0,
  });

  /// L'identifiant de l'attaquant.
  ///
  /// Valeurs possibles : "player" ou "enemy".
  final String attacker;

  /// L'attaque utilisée.
  final BattleMove move;

  /// L'identifiant de la cible.
  ///
  /// Valeurs possibles : "player", "enemy" ou "field" pour un move qui agit
  /// sur le champ plutôt que sur un combattant.
  final String target;

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

~~~~

### `packages/map_battle/lib/src/battle_session.dart`

~~~~dart
import 'battle_setup.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

const double _criticalHitMultiplier = 1.5;
const int _supportedWeatherDurationTurns = 5;
const int _supportedPseudoWeatherDurationTurns = 5;
const Set<String> _sandstormResidualImmuneTypes = <String>{
  'ground',
  'rock',
  'steel',
};

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
  // Le runtime peut maintenant fournir les PV courants réels du Pokémon actif.
  // On garde néanmoins un fallback explicite sur les PV max pour préserver les
  // anciens call sites/tests qui n'avaient pas besoin de cet état.
  final playerCurrentHp = _clampHp(
    currentHp: setup.playerPokemon.currentHp,
    maxHp: setup.playerPokemon.maxHp,
  );
  final enemyCurrentHp = _clampHp(
    currentHp: setup.enemyPokemon.currentHp,
    maxHp: setup.enemyPokemon.maxHp,
  );

  // Convertir les données de setup en combattants
  final player = BattleCombatant(
    speciesId: setup.playerPokemon.speciesId,
    level: setup.playerPokemon.level,
    currentHp: playerCurrentHp,
    maxHp: setup.playerPokemon.maxHp,
    stats: setup.playerPokemon.stats,
    typing: setup.playerPokemon.typing,
    majorStatus: setup.playerPokemon.majorStatus,
    volatileState: setup.playerPokemon.volatileState,
    abilityId: setup.playerPokemon.abilityId,
    // Le contrat battle enrichi doit survivre jusqu'à l'état de session :
    // - `type` et `target` restent surtout descriptifs à ce stade ;
    // - `priority` est déjà consommée depuis BE3 ;
    // - `accuracy` et `currentPp` deviennent réellement actives en BE4.
    // - `critRatio` devient réellement consommé en BE6.
    moves: setup.playerPokemon.moves
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
        .toList(),
  );

  final enemy = BattleCombatant(
    speciesId: setup.enemyPokemon.speciesId,
    level: setup.enemyPokemon.level,
    currentHp: enemyCurrentHp,
    maxHp: setup.enemyPokemon.maxHp,
    stats: setup.enemyPokemon.stats,
    typing: setup.enemyPokemon.typing,
    majorStatus: setup.enemyPokemon.majorStatus,
    volatileState: setup.enemyPokemon.volatileState,
    abilityId: setup.enemyPokemon.abilityId,
    // Même règle pour l'adversaire : on ne reperd aucune dimension déjà jugée
    // honnête dans le contrat battle minimal.
    moves: setup.enemyPokemon.moves
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
        .toList(),
  );

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    player: player,
    enemy: enemy,
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

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [getAvailableChoices] récupère les choix disponibles
/// 3. [applyChoice] applique un choix et retourne une nouvelle session
/// 4. Répéter 2-3 jusqu'à ce que [state.isFinished] soit true
/// 5. Récupérer [state.outcome] pour le résultat final
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

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// À appeler quand [state.phase] == [BattlePhase.playerChoice].
  ///
  /// Retourne une liste de choix :
  /// - [PlayerBattleChoiceFight] pour chaque attaque disponible (0-3)
  /// - [PlayerBattleChoiceCapture] pour capturer, uniquement en sauvage quand
  ///   le runtime a explicitement autorisé cette issue
  /// - [PlayerBattleChoiceRun] pour fuir, uniquement en combat sauvage
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final choices = session.getAvailableChoices();
  /// // wild: [Fight(0), Fight(1), Fight(2), Fight(3), Capture(), Run()]
  /// // trainer: [Fight(0), Fight(1), Fight(2), Fight(3)]
  /// ```
  List<PlayerBattleChoice> getAvailableChoices() {
    final forcedChoice = _forcedPlayerChoice();
    if (forcedChoice != null) {
      return <PlayerBattleChoice>[forcedChoice];
    }

    // BE4 arrête ici un autre mensonge discret :
    // - un move à 0 PP ne doit plus apparaître comme un choix valide ;
    // - on conserve néanmoins l'index réel du slot pour que l'UI/runtime
    //   continue à référencer le vrai move dans la liste du combattant ;
    // - on n'ouvre toujours pas Struggle, donc un Pokémon peut n'avoir aucun
    //   choix `Fight` restant.
    final fightChoices = <PlayerBattleChoice>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        fightChoices.add(PlayerBattleChoiceFight(i));
      }
    }

    // Invariants métier lots 11 + 13 :
    // - la fuite est autorisée en sauvage pour garder une vraie boucle jouable ;
    // - la capture n'est autorisée qu'en sauvage ;
    // - la capture n'est proposée que si le runtime a validé qu'elle pourra
    //   être écrite honnêtement (party avec place, pas de trainer battle) ;
    // - trainer battle : ni Run ni Capture ne doivent apparaître.
    if (!setup.isTrainerBattle && setup.allowCapture) {
      fightChoices.add(const PlayerBattleChoiceCapture());
    }

    // On filtre donc Run ici pour que l'UI/runtime n'ait pas de bouton
    // de fuite à afficher en trainer battle.
    if (!setup.isTrainerBattle) {
      fightChoices.add(const PlayerBattleChoiceRun());
    }

    return fightChoices;
  }

  PlayerBattleChoice? _forcedPlayerChoice() {
    final volatileState = state.player.volatileState;
    if (!volatileState.mustRecharge && volatileState.pendingCharge == null) {
      return null;
    }

    // BE8 choisit ici la plus petite surface publique honnête :
    // - le joueur ne re-sélectionne pas un move librement pendant une
    //   recharge ou la libération d'un move déjà chargé ;
    // - on expose donc un simple "continuer" au lieu de maquiller ce tour
    //   forcé avec un faux bouton de move.
    return const PlayerBattleChoiceContinue();
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
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
    final forcedPlayerAction = _resolveForcedAction(
      combatantLabel: 'player',
      combatant: state.player,
    );
    if (forcedPlayerAction != null && choice is! PlayerBattleChoiceContinue) {
      throw StateError(
        'Ce tour joueur est forcé; il faut l’acquitter avec PlayerBattleChoiceContinue.',
      );
    }
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue est réservé aux tours forcés BE8.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (forcedPlayerAction == null &&
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
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
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
    if (forcedPlayerAction == null && choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: state.player,
        enemy: state.enemy,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          player: finalState.player,
          enemy: finalState.enemy,
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
    // - pas de système de switch ni de before-turn hooks ;
    // - BE7 ajoute seulement un résiduel de fin de tour local pour les
    //   statuts majeurs supportés ;
    // - juste le plus petit mécanisme honnête pour les deux actions de ce
    //   tour et leur clôture immédiate.
    final resolvedTurn = _resolveTurn(playerAction, enemyAction);

    // Phase 4: Récupérer l'état résultant après dégâts + éventuels boosts.
    final newPlayer = resolvedTurn.player;
    final newEnemy = resolvedTurn.enemy;

    // Phase 5: Vérifier si le combat est fini
    final outcome = _determineOutcome(
      newPlayer,
      newEnemy,
      resolvedTurn.field,
    );

    // Phase 6: Créer le nouvel état
    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      player: newPlayer,
      enemy: newEnemy,
      field: resolvedTurn.field,
      // On conserve maintenant la trace du dernier tour même s'il termine le
      // combat :
      // - sinon un K.O. au résiduel, une paralysie bloquante ou une
      //   application de statut terminale redeviendraient invisibles ;
      // - `Run` et `Capture` gardent toujours `currentTurn == null`, car ils ne
      //   passent pas par `_resolveTurn`.
      currentTurn: resolvedTurn.turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: resolvedTurn.rng,
    );
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
      // Fallback: première attaque si index invalide
      final fallbackMove = state.player.moves.first;
      if (!fallbackMove.hasUsablePp) {
        throw StateError(
          'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
        );
      }
      return BattleActionFight(
        fallbackMove,
        moveIndex: 0,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
    }
    // Fallback: première attaque
    final fallbackMove = state.player.moves.first;
    if (!fallbackMove.hasUsablePp) {
      throw StateError(
        'Aucun fallback honnête possible : le move par défaut n’a plus de PP.',
      );
    }
    return BattleActionFight(
      fallbackMove,
      moveIndex: 0,
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
    var player = state.player;
    var enemy = state.enemy;
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
          } else if (orderedAction.action is BattleActionRecharge) {
            if (player.isFainted || enemy.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'player',
              combatant: player,
            );
            player = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
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
          } else if (orderedAction.action is BattleActionRecharge) {
            if (enemy.isFainted || player.isFainted) {
              continue;
            }
            final resolution = _resolveRechargeAction(
              combatantLabel: 'enemy',
              combatant: enemy,
            );
            enemy = resolution.combatant;
            volatileEvents.addAll(resolution.volatileEvents);
          }
      }
    }

    final residualResolution = _resolveEndOfTurnPhase(
      player: player,
      enemy: enemy,
      field: field,
    );
    player = residualResolution.player;
    enemy = residualResolution.enemy;
    field = residualResolution.field;
    statusEvents.addAll(residualResolution.statusEvents);
    fieldEvents.addAll(residualResolution.fieldEvents);
    player = player.withVolatileState(
      player.volatileState.clearedEndOfTurnFlags(),
    );
    enemy = enemy.withVolatileState(
      enemy.volatileState.clearedEndOfTurnFlags(),
    );

    return _ResolvedBattleTurn(
      player: player,
      enemy: enemy,
      field: field,
      rng: turnRng,
      turnResult: BattleTurnResult(
        playerAction: playerAction,
        enemyAction: enemyAction,
        executions: executions,
        statusEvents: statusEvents,
        volatileEvents: volatileEvents,
        fieldEvents: fieldEvents,
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
    final trickRoomActive =
        field.isPseudoWeatherActive(BattlePseudoWeatherId.trickRoom);
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
    return action is BattleActionFight || action is BattleActionRecharge;
  }

  int _priorityForResolvedAction(BattleAction action) {
    return switch (action) {
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
    final pendingCharge = attacker.volatileState.pendingCharge;
    final isChargeRelease = pendingCharge != null &&
        pendingCharge.moveIndex == moveIndex &&
        pendingCharge.moveId == move.id;

    if (!isChargeRelease && !move.hasUsablePp) {
      throw StateError(
        'Le move "${move.name}" n’a plus de PP et ne peut pas être résolu honnêtement.',
      );
    }

    // Ordre de résolution BE8, volontairement borné et documenté :
    // 1. si le move est la libération d'une charge déjà stockée, on réutilise
    //    ce move sans repayer les PP et on nettoie immédiatement l'état de
    //    charge ;
    // 2. sinon, on suit BE4 : tentative => consommation de PP ;
    // 3. blocage d'action par paralysie si applicable ;
    // 4. si le move est un chargeThenStrike en premier tour, on entre en
    //    charge et on s'arrête là ;
    // 5. hit check ;
    // 6. application éventuelle de `protect` sur le lanceur, puis interception
    //    par une protection adverse déjà active ;
    // 7. dégâts / statuts / BE5 / BE6 / BE7 ;
    // 8. éventuelle recharge forcée si le move le demande.
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
    final actionGate = _resolveMajorStatusActionGate(
      combatantLabel: attackerLabel,
      combatant: attackerAfterPpUse,
      rng: rng,
    );

    if (!actionGate.canAct) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: actionGate.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    if (!isChargeRelease && move.chargeThenStrikeEffect != null) {
      final chargingAttacker = attackerAfterPpUse.withVolatileState(
        attackerAfterPpUse.volatileState.withPendingCharge(
          BattlePendingChargeState(
            moveIndex: moveIndex,
            moveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ),
      );

      return _ResolvedMoveExecution(
        attacker: chargingAttacker,
        defender: defender,
        field: field,
        rng: actionGate.nextRng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: <BattleVolatileEvent>[
          BattleVolatileEvent.chargeStarted(
            actor: attackerLabel,
            sourceMoveId: move.id,
            chargeStateId: move.chargeThenStrikeEffect!.chargeStateId,
          ),
        ],
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final volatileEvents = <BattleVolatileEvent>[
      if (isChargeRelease)
        BattleVolatileEvent.chargeReleased(
          actor: attackerLabel,
          sourceMoveId: move.id,
          chargeStateId: pendingCharge.chargeStateId,
        ),
    ];

    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionGate.nextRng,
    );

    if (!hitCheck.didHit) {
      return _ResolvedMoveExecution(
        attacker: attackerAfterPpUse,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: attackerAfterPpUse.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: false,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final protectResolution = _resolveProtectInteractions(
      move: move,
      attackerLabel: attackerLabel,
      targetLabel: targetLabel,
      attacker: attackerAfterPpUse,
      defender: defender,
    );
    volatileEvents.addAll(protectResolution.volatileEvents);

    if (protectResolution.blockedByProtect) {
      return _ResolvedMoveExecution(
        attacker: protectResolution.attacker,
        defender: protectResolution.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: BattleMoveExecution(
          attacker: attackerLabel,
          move: protectResolution.attacker.moves[moveIndex],
          target: _resolveExecutionTargetLabel(
            move: move,
            attackerLabel: attackerLabel,
            opponentLabel: targetLabel,
          ),
          damage: 0,
          didHit: true,
          didCrit: false,
          criticalMultiplier: 1.0,
        ),
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: protectResolution.attacker,
      defender: protectResolution.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    // BE5 donne à l'immunité une sémantique simple et honnête pour le petit
    // sous-ensemble moteur actuellement supporté :
    // - le move a bien été tenté et a passé le hit check ;
    // - mais il n'a "aucun effet" sur la cible si le typing annule le hit ;
    // - on n'applique donc ni dégâts ni stage changes à partir d'un hit
    //   immunisé, ce qui évite des demi-effets mensongers.
    final updatedAttacker = damageResult.wasImmune
        ? protectResolution.attacker
        : protectResolution.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? protectResolution.defender
        : protectResolution.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final statusApplication = _resolveMajorStatusApplication(
      move: move,
      targetLabel: targetLabel,
      defender: defenderAfterHit,
      damageResult: damageResult,
      rng: damageResult.nextRng,
    );
    final fieldApplication = _resolveFieldApplication(
      move: move,
      field: field,
    );
    final rechargeFollowUp = _resolveRechargeFollowUp(
      move: move,
      attackerLabel: attackerLabel,
      attacker: updatedAttacker,
      damageResult: damageResult,
    );
    volatileEvents.addAll(rechargeFollowUp.volatileEvents);

    return _ResolvedMoveExecution(
      attacker: rechargeFollowUp.attacker,
      defender: statusApplication.defender,
      field: fieldApplication.field,
      rng: statusApplication.nextRng,
      execution: BattleMoveExecution(
        attacker: attackerLabel,
        move: rechargeFollowUp.attacker.moves[moveIndex],
        // BE1 ne laisse plus `target` se reperdre au moment de la trace
        // d'exécution :
        // - un move `self` doit apparaître comme ciblant le lanceur ;
        // - un move `opponent` garde la cible adverse résolue du tour ;
        // - `unspecified` reste le fallback de compatibilité des anciens call
        //   sites qui construisaient des moves battle pauvres à la main.
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
      ),
      statusEvents: statusApplication.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(volatileEvents),
      fieldEvents: fieldApplication.fieldEvents,
    );
  }

  _ResolvedProtectInteractions _resolveProtectInteractions({
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
      return _ResolvedProtectInteractions(
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
      return _ResolvedProtectInteractions(
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
    return _ResolvedProtectInteractions(
      attacker: updatedAttacker,
      defender: updatedDefender,
      blockedByProtect: true,
      volatileEvents: volatileEvents,
    );
  }

  _ResolvedRechargeFollowUp _resolveRechargeFollowUp({
    required BattleMove move,
    required String attackerLabel,
    required BattleCombatant attacker,
    required _ResolvedDamage damageResult,
  }) {
    // BE8 borne `requireRecharge` au sous-ensemble local réellement défendable :
    // - le move doit avoir atteint la phase "dégâts calculés" ;
    // - un miss ou un blocage par Protect sort déjà plus haut ;
    // - une immunité complète ne déclenche pas ce verrou, car aucun effet
    //   offensif réel n'a finalement été produit ;
    // - on ne prétend toujours pas reproduire tous les cas spéciaux Pokémon.
    if (!move.requiresRecharge ||
        move.resolvedCategory == BattleMoveCategory.status ||
        damageResult.wasImmune) {
      return _ResolvedRechargeFollowUp(
        attacker: attacker,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeFollowUp(
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

  _ResolvedRechargeAction _resolveRechargeAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (!combatant.volatileState.mustRecharge) {
      return _ResolvedRechargeAction(
        combatant: combatant,
        volatileEvents: const <BattleVolatileEvent>[],
      );
    }

    return _ResolvedRechargeAction(
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

  _ResolvedFieldApplication _resolveFieldApplication({
    required BattleMove move,
    required BattleFieldState field,
  }) {
    // BE9 garde un contrat de champ petit et explicite :
    // - un move ne pose au maximum qu'une météo OU un pseudoWeather ;
    // - aucune pile générique d'effets de champ ;
    // - aucune side/slot condition cachée derrière ce helper.
    if (move.weatherEffect == null && move.pseudoWeatherEffect == null) {
      return _ResolvedFieldApplication(
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
          remainingTurns: _supportedWeatherDurationTurns,
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
      // Recadrage volontaire :
      // - BE9 ne crée pas un "room system" générique ;
      // - mais Trick Room réutilisé pendant qu'il est déjà actif doit rester
      //   honnête pour le sous-ensemble local ;
      // - on choisit donc un toggle simple : pose si absent, retrait si déjà
      //   actif, sans rouvrir d'autre mécanique de restart.
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
            remainingTurns: _supportedPseudoWeatherDurationTurns,
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

    return _ResolvedFieldApplication(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
    );
  }

  _ResolvedActionGate _resolveMajorStatusActionGate({
    required String combatantLabel,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    final status = combatant.majorStatus;
    if (status?.id != BattleMajorStatusId.par) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ouvre ici la plus petite sémantique honnête de paralysie :
    // - le move a déjà consommé 1 PP, car la tentative a bien eu lieu ;
    // - on bloque ensuite l'action avec une chance fixe de 25% ;
    // - on ne touche ni à l'ordre BE3 déjà figé, ni au hit check BE4.
    final roll = rng.nextChance(
      numerator: 1,
      denominator: 4,
    );
    if (!roll.didOccur) {
      return _ResolvedActionGate(
        canAct: true,
        nextRng: roll.next,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    return _ResolvedActionGate(
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

  _ResolvedStatusApplication _resolveMajorStatusApplication({
    required BattleMove move,
    required String targetLabel,
    required BattleCombatant defender,
    required _ResolvedDamage damageResult,
    required BattleRng rng,
  }) {
    final effect = move.majorStatusEffect;
    if (effect == null) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    // BE7 ne crée pas encore de couche complète d'immunité de statut.
    // En revanche, pour un move qui inflige aussi des dégâts, on refuse
    // d'appliquer un statut si le hit a été entièrement annulé par une
    // immunité de type déjà supportée par BE5.
    if (damageResult.wasImmune &&
        move.resolvedCategory != BattleMoveCategory.status) {
      return _ResolvedStatusApplication(
        defender: defender,
        nextRng: rng,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    if (defender.majorStatus != null) {
      return _ResolvedStatusApplication(
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
        return _ResolvedStatusApplication(
          defender: defender,
          nextRng: chanceRoll.next,
          statusEvents: const <BattleStatusEvent>[],
        );
      }

      return _ResolvedStatusApplication(
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

    return _ResolvedStatusApplication(
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

  _ResolvedResidualPhase _resolveEndOfTurnPhase({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    // BE9 restructure explicitement la fin de tour, sans créer un système
    // général de hooks :
    // 1. résiduels de statuts majeurs déjà ouverts en BE7 ;
    // 2. résiduels météo supportés en BE9 ;
    // 3. décrémentation puis expiration du champ ;
    // 4. l'outcome final est ensuite déterminé plus haut, à partir de l'état
    //    réellement obtenu après ces effets.
    final statusResidual = _applyEndOfTurnMajorStatusResiduals(
      player: player,
      enemy: enemy,
    );
    final weatherResidual = _applyEndOfTurnWeatherResiduals(
      player: statusResidual.player,
      enemy: statusResidual.enemy,
      field: field,
    );
    final fieldProgression =
        _advanceFieldStateAtEndOfTurn(weatherResidual.field);

    return _ResolvedResidualPhase(
      player: weatherResidual.player,
      enemy: weatherResidual.enemy,
      field: fieldProgression.field,
      statusEvents: statusResidual.statusEvents,
      fieldEvents: <BattleFieldEvent>[
        ...weatherResidual.fieldEvents,
        ...fieldProgression.fieldEvents,
      ],
    );
  }

  _ResolvedMajorStatusResiduals _applyEndOfTurnMajorStatusResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
  }) {
    // BE7 reste volontairement local :
    // - pas de "hook system" de fin de tour ;
    // - pas de queue de résiduels générique ;
    // - juste la plus petite phase explicite pour les statuts majeurs
    //   supportés, après les actions et avant l'outcome final.
    final playerResidual = !player.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: player,
            combatantLabel: 'player',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );
    final enemyResidual = !enemy.isFainted
        ? _applyEndOfTurnResidualForCombatant(
            combatant: enemy,
            combatantLabel: 'enemy',
          )
        : const _ResolvedSingleResidual(
            combatant: null,
            statusEvents: <BattleStatusEvent>[],
          );

    return _ResolvedMajorStatusResiduals(
      player: playerResidual.combatant ?? player,
      enemy: enemyResidual.combatant ?? enemy,
      statusEvents: <BattleStatusEvent>[
        ...playerResidual.statusEvents,
        ...enemyResidual.statusEvents,
      ],
    );
  }

  _ResolvedSingleResidual _applyEndOfTurnResidualForCombatant({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    final status = combatant.majorStatus;
    if (status == null || combatant.isFainted) {
      return _ResolvedSingleResidual(
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
      return _ResolvedSingleResidual(
        combatant: combatant,
        statusEvents: const <BattleStatusEvent>[],
      );
    }

    final damagedCombatant = combatant.withDamage(residualDamage);
    final nextCombatant =
        status.id == BattleMajorStatusId.tox && !damagedCombatant.isFainted
            ? damagedCombatant.withMajorStatus(status.incrementToxicCounter())
            : damagedCombatant;

    return _ResolvedSingleResidual(
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

  _ResolvedWeatherResiduals _applyEndOfTurnWeatherResiduals({
    required BattleCombatant player,
    required BattleCombatant enemy,
    required BattleFieldState field,
  }) {
    final weather = field.weather;
    if (weather == null || weather.id != BattleWeatherId.sandstorm) {
      return _ResolvedWeatherResiduals(
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

    return _ResolvedWeatherResiduals(
      player: playerResidual.combatant,
      enemy: enemyResidual.combatant,
      field: field,
      fieldEvents: <BattleFieldEvent>[
        ...playerResidual.fieldEvents,
        ...enemyResidual.fieldEvents,
      ],
    );
  }

  _ResolvedSandstormResidual _applySandstormResidual({
    required BattleCombatant combatant,
    required String combatantLabel,
  }) {
    if (combatant.isFainted || _isImmuneToSandstormResidual(combatant)) {
      return _ResolvedSandstormResidual(
        combatant: combatant,
        fieldEvents: const <BattleFieldEvent>[],
      );
    }

    final damage = _fractionalResidual(
      maxHp: combatant.maxHp,
      numerator: 1,
      denominator: 16,
    );
    final damagedCombatant = combatant.withDamage(damage);

    return _ResolvedSandstormResidual(
      combatant: damagedCombatant,
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

  _ResolvedFieldProgression _advanceFieldStateAtEndOfTurn(
      BattleFieldState field) {
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

    return _ResolvedFieldProgression(
      field: updatedField,
      fieldEvents: List<BattleFieldEvent>.unmodifiable(fieldEvents),
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
    final burnMultiplier =
        attacker.majorStatus?.id == BattleMajorStatusId.brn &&
                move.resolvedCategory == BattleMoveCategory.physical
            ? 0.5
            : 1.0;
    final weatherMultiplier = _resolveWeatherDamageMultiplier(
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

  double _resolveWeatherDamageMultiplier({
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
    // - BE7 y ajoute ensuite le malus simple de paralysie ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    if (combatant.majorStatus?.id != BattleMajorStatusId.par) {
      return stagedSpeed;
    }

    final slowedSpeed = (stagedSpeed * 0.5).floor();
    return slowedSpeed < 1 ? 1 : slowedSpeed;
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
  /// Règles :
  /// - Si enemy.isFainted → victoire
  /// - Si player.isFainted → défaite
  /// - Sinon → combat continue (null)
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleCombatant player,
    BattleCombatant enemy,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemy.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
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
    if (player.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        player: player,
        enemy: enemy,
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
    required this.player,
    required this.enemy,
    required this.field,
    required this.rng,
    required this.turnResult,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleTurnResult turnResult;
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
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedActionGate {
  const _ResolvedActionGate({
    required this.canAct,
    required this.nextRng,
    required this.statusEvents,
  });

  final bool canAct;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
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

class _ResolvedStatusApplication {
  const _ResolvedStatusApplication({
    required this.defender,
    required this.nextRng,
    required this.statusEvents,
  });

  final BattleCombatant defender;
  final BattleRng nextRng;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedProtectInteractions {
  const _ResolvedProtectInteractions({
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

class _ResolvedRechargeFollowUp {
  const _ResolvedRechargeFollowUp({
    required this.attacker,
    required this.volatileEvents,
  });

  final BattleCombatant attacker;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedRechargeAction {
  const _ResolvedRechargeAction({
    required this.combatant,
    required this.volatileEvents,
  });

  final BattleCombatant combatant;
  final List<BattleVolatileEvent> volatileEvents;
}

class _ResolvedResidualPhase {
  const _ResolvedResidualPhase({
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

class _ResolvedMajorStatusResiduals {
  const _ResolvedMajorStatusResiduals({
    required this.player,
    required this.enemy,
    required this.statusEvents,
  });

  final BattleCombatant player;
  final BattleCombatant enemy;
  final List<BattleStatusEvent> statusEvents;
}

class _ResolvedWeatherResiduals {
  const _ResolvedWeatherResiduals({
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

class _ResolvedSandstormResidual {
  const _ResolvedSandstormResidual({
    required this.combatant,
    required this.fieldEvents,
  });

  final BattleCombatant combatant;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldProgression {
  const _ResolvedFieldProgression({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedFieldApplication {
  const _ResolvedFieldApplication({
    required this.field,
    required this.fieldEvents,
  });

  final BattleFieldState field;
  final List<BattleFieldEvent> fieldEvents;
}

class _ResolvedSingleResidual {
  const _ResolvedSingleResidual({
    required this.combatant,
    required this.statusEvents,
  });

  final BattleCombatant? combatant;
  final List<BattleStatusEvent> statusEvents;
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

### `packages/map_battle/lib/src/battle_setup.dart`

~~~~dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Configuration initiale d'un combat.
///
/// Modèle pur, sans dépendance runtime.
/// Construit depuis [BattleStartRequest] par le runtime via un mapper dédié.
///
/// Ce modèle contient uniquement les données nécessaires au moteur de combat,
/// sans aucune référence à l'orchestration runtime (OverworldReturnContext, etc.).
class BattleSetup {
  /// Crée une configuration de combat.
  ///
  /// [playerPokemon] - Le Pokémon du joueur qui combat.
  /// [enemyPokemon] - Le Pokémon adverse qui combat.
  /// [isTrainerBattle] - true si c'est un combat contre un dresseur.
  /// [trainerId] - L'identifiant du dresseur (non-null si [isTrainerBattle] est true).
  /// [allowCapture] - true si le runtime autorise explicitement la capture
  ///   pour ce combat. Le lot 13 l'utilise uniquement pour les rencontres
  ///   sauvages quand la party a encore de la place.
  /// [fieldState] - État de champ initial si le setup battle veut démarrer
  ///   sous une météo ou un pseudoWeather déjà actifs.
  const BattleSetup({
    required this.playerPokemon,
    required this.enemyPokemon,
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
    this.fieldState = const BattleFieldState(),
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// true si c'est un combat contre un dresseur.
  ///
  /// Si false, c'est une rencontre sauvage (wild battle).
  final bool isTrainerBattle;

  /// L'identifiant du dresseur.
  ///
  /// Non-null si [isTrainerBattle] est true.
  /// Utilisé par le runtime pour marquer `trainer_defeated:{trainerId}` après victoire.
  final String? trainerId;

  /// true si l'action Capture doit être exposée au joueur.
  ///
  /// Invariants métier lot 13 :
  /// - jamais en combat trainer ;
  /// - seulement si le runtime sait qu'une capture réussie peut être écrite
  ///   proprement dans l'état joueur ;
  /// - on évite ainsi toute promesse mensongère quand la party est pleine.
  final bool allowCapture;

  /// État de champ initial du combat.
  ///
  /// BE9 le porte dès le setup pour garder le champ observable :
  /// - le runtime principal démarre encore avec un champ vide ;
  /// - mais les tests et call sites directs peuvent injecter une pluie,
  ///   une tempête de sable ou un Trick Room déjà actifs ;
  /// - cela évite des mutations post-création qui mentiraient sur l'état
  ///   initial réellement résolu.
  final BattleFieldState fieldState;
}

/// Données minimales d'un combattant pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleCombatant] est utilisé à la place.
class BattleCombatantData {
  /// Crée les données d'un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce (ex: "pikachu", "lapras").
  /// [level] - Le niveau du combattant.
  /// [maxHp] - Les points de vie maximum.
  /// [currentHp] - Les PV courants si le runtime les connaît déjà.
  /// [stats] - Snapshot résolu des stats non-HP réellement exploitées par le
  /// moteur battle.
  /// [typing] - Typing défensif/offensif minimal du combattant si connu.
  /// [majorStatus] - Statut majeur initial si un call site battle direct veut
  ///   démarrer depuis un état déjà entamé.
  /// [volatileState] - Sous-état volatile local BE8 si un setup battle direct
  ///   veut démarrer depuis une protection, une recharge ou une charge déjà
  ///   en cours.
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  ///
  /// Le lot 9 du runtime -> battle handoff doit partir de la vraie party du
  /// joueur. On ajoute donc ce champ optionnel au setup pour éviter de soigner
  /// implicitement le Pokémon actif lors de l'ouverture du combat.
  /// [moves] - La liste des attaques disponibles (4 max).
  const BattleCombatantData({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Le niveau du combattant.
  final int level;

  /// Les points de vie maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP pour ce combattant.
  ///
  /// BE2 choisit un vrai contrat typé ici pour deux raisons :
  /// - le moteur ne doit plus inventer implicitement des valeurs offensives /
  ///   défensives à partir de rien ;
  /// - le runtime est la bonne frontière pour résoudre ces stats à partir des
  ///   species data, du niveau et des IV/EV disponibles.
  ///
  /// `speed` est déjà transportée pour arrêter sa perte silencieuse, même si
  /// elle est maintenant consommée pour l'ordre d'action honnête minimal.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le handoff le connaît déjà.
  ///
  /// BE5 choisit ici une compatibilité volontairement bornée :
  /// - le vrai chemin runtime -> battle doit fournir cette donnée ;
  /// - les anciens call sites directs de `map_battle` peuvent encore l'omettre
  ///   pour éviter une migration parasite de tout le package ;
  /// - en l'absence de typing, le moteur reste neutre sur STAB/effectiveness
  ///   au lieu d'inventer un type mensonger.
  final BattleTypingSnapshot? typing;

  /// Statut majeur initial du combattant si le setup battle le connaît déjà.
  ///
  /// Le chemin runtime principal le laisse à `null` dans BE7 :
  /// - la persistance hors combat des statuts n'existe pas encore ;
  /// - mais le moteur battle a maintenant besoin d'un vrai état local de
  ///   statut majeur ;
  /// - garder ce champ optionnel évite aussi d'inventer des helpers de test
  ///   parallèles juste pour démarrer un combat déjà brûlé / paralysé / etc.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local du combattant au démarrage.
  ///
  /// Le chemin runtime principal le laisse vide dans BE8 :
  /// - il n'existe pas encore de persistance hors combat de `Protect`,
  ///   `mustRecharge` ou des moves chargés ;
  /// - mais garder ce champ directement sur le setup battle permet des tests
  ///   honnêtes sans mutation post-création de session.
  final BattleVolatileState volatileState;

  /// Les points de vie courants si le handoff runtime les fournit déjà.
  ///
  /// Si null, le moteur démarre le combat à pleine vie, ce qui conserve le
  /// comportement historique des tests et call sites qui n'ont pas besoin de
  /// porter cet état.
  final int? currentHp;

  /// L'ability réellement résolue si le runtime la connaît déjà.
  ///
  /// Le moteur de combat MVP n'utilise pas encore cette donnée pour ses
  /// calculs, mais le lot 13 en a besoin pour construire un Pokémon capturé
  /// sans réinventer un deuxième format intermédiaire.
  final String abilityId;

  /// La liste des attaques disponibles.
  final List<BattleMoveData> moves;
}

/// Données minimales d'une attaque pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleMove] est utilisé à la place.
///
/// Mini-fix BE6-2 :
/// - ce contrat de setup devient lui aussi `final` ;
/// - il doit rester un petit DTO battle, pas une surface extensible ;
/// - verrouiller aussi le setup évite de fermer `BattleMove` tout en laissant
///   encore entrer des valeurs malformées par héritage avant la création de
///   session ;
/// - on garde `const`, les assertions locales, puis les gardes runtime comme
///   défense en profondeur, mais le bypass trivial par override disparaît.
final class BattleMoveData {
  /// Crée les données d'une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté puis consommé pour la couche type
  ///   minimale ouverte en BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision battle minimale réellement consommée par BE4.
  /// [pp] - Le PP max transporté vers le moteur.
  /// [currentPp] - Le PP courant initial si un call site battle direct veut
  ///   forcer un état de combat déjà entamé.
  /// [priority] - Priorité canonique transportée et consommée par BE3 pour
  ///   l'ordre d'action minimal honnête.
  /// [critRatio] - Ratio critique minimal transporté et consommé par BE6.
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal supporté par
  ///   BE7 pour le petit sous-ensemble de statuts majeurs réellement
  ///   exécutable.
  /// [selfVolatileStatus] - Volatile auto-appliqué par le move dans le
  ///   sous-ensemble strict BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [breaksProtect] - Le move peut bypasser une protection active BE8.
  /// [requiresRecharge] - Le move impose ensuite un tour de recharge au
  ///   lanceur.
  /// [chargeThenStrikeEffect] - Le move charge un tour puis frappe le tour
  ///   suivant sans repayer les PP.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  ///
  /// Ce contrat reste volontairement petit :
  /// - il ne copie pas `PokemonMove` ;
  /// - il ne prétend pas transporter tous les `effects` canoniques ;
  /// - mais BE1 y ajoute aussi quelques dimensions battle fondamentales
  ///   (`type`, `target`, `pp`) pour arrêter leur perte silencieuse ;
  /// - puis BE3 et BE4 commencent à consommer réellement `priority`,
  ///   `speed`, `accuracy` et les PP ;
  /// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
  /// - puis BE7 ouvre un unique effet `applyStatus` battle minimal pour
  ///   `par`, `brn`, `psn`, `tox` ;
  /// - puis BE8 ajoute quelques volatiles utiles explicitement bornés aux
  ///   besoins de `Protect`, `breakProtect`, `requireRecharge` et
  ///   `chargeThenStrike` ;
  /// - puis BE9 ajoute uniquement la météo et le pseudoWeather réellement
  ///   consommés par le moteur (`rain`, `sandstorm`, `trickRoom`) ;
  /// - le reste reste explicitement hors scope.
  const BattleMoveData({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    this.currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  })  : assert(
          critRatio >= 1,
          'BattleMoveData critRatio must be >= 1.',
        ),
        _critRatio = critRatio;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Depuis BE2, cette donnée n'est plus utilisée seule :
  /// - `power` reste bien la base du damage contract ;
  /// - mais le moteur la combine maintenant avec les vraies stats résolues
  ///   du combattant et de sa cible ;
  /// - un move de statut garde `power <= 0` et inflige donc 0 dégât.
  final int power;

  /// Type canonique du move.
  ///
  /// Donnée transportée dès BE1 pour éviter sa perte silencieuse au handoff.
  ///
  /// BE5 commence enfin à la consommer réellement pour :
  /// - le STAB ;
  /// - l'efficacité de type ;
  /// - les immunités.
  ///
  /// Les anciens call sites directs peuvent encore garder la valeur par défaut
  /// `"unknown"` : dans ce cas, le moteur reste neutre au lieu de prétendre
  /// connaître un type qu'il n'a pas.
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Ce champ est optionnel pour préserver les anciens call sites/tests qui ne
  /// transportaient encore que `power`.
  final BattleMoveCategory? category;

  /// Cible battle minimale résolue par le bridge runtime.
  ///
  /// Le moteur n'en tire pas encore une logique complète de targeting, mais le
  /// handoff ne doit plus jeter cette information quand elle reste simple et
  /// honnête dans le cadre 1v1 actuel.
  ///
  /// BE9 ajoute aussi `BattleMoveTarget.field` pour les moves qui posent une
  /// météo ou un pseudoWeather réellement consommés par le moteur.
  final BattleMoveTarget target;

  /// Contrat minimal de précision battle.
  ///
  /// BE4 ouvre enfin un vrai hit pipeline honnête :
  /// - le moteur n'a plus besoin que le runtime neutralise l'accuracy ;
  /// - `alwaysHits` et `percent` suffisent pour le sous-ensemble supporté ;
  /// - le reste des mécaniques de précision reste hors scope.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move.
  ///
  /// `BattleMoveData` reste un contrat de setup :
  /// - `pp` décrit la capacité max du move ;
  /// - `currentPp`, si fourni, permet seulement d'initialiser un état battle
  ///   déjà entamé ;
  /// - sinon, le moteur démarre à pleine valeur.
  ///
  /// Compatibilité volontairement bornée :
  /// - le chemin runtime -> battle fournit déjà le PP canonique réel ;
  /// - les anciens call sites `map_battle` directs n'avaient souvent aucun PP
  ///   explicite et supposaient juste "move utilisable" ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration massive hors scope ;
  /// - ce défaut n'est pas une vérité Pokédex : c'est un garde-fou de
  ///   compatibilité pour les setups battle locaux, documenté comme tel.
  final int pp;

  /// Valeur courante de PP au démarrage de la session si connue.
  ///
  /// Le runtime principal n'en a pas besoin aujourd'hui :
  /// - les combats commencent encore avec tous les PP pleins ;
  /// - la write-back des PP reste hors scope.
  ///
  /// En revanche, ce champ rend le contrat battle direct plus honnête et
  /// simplifie les tests ciblés de BE4 sans bricoler l'état après coup.
  final int? currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE1 refusait encore `priority != 0` parce que le moteur résolvait
  /// toujours "joueur puis ennemi". BE3 ouvre enfin ce champ :
  /// - il est transporté dès le setup ;
  /// - il est consommé ensuite par `BattleSession` pour l'ordre du tour ;
  /// - mais il ne crée pas pour autant une vraie queue générique.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 reste volontairement petit :
  /// - on transporte seulement l'entier canonique déjà présent côté runtime ;
  /// - le moteur battle l'interprète via une table locale explicite ;
  /// - on n'ouvre pas les règles avancées de critique du jeu complet.
  ///
  /// Valeur neutre :
  /// - `1` correspond au ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - comme pour `BattleMove`, ce contrat de setup reste `const` pour ne pas
  ///   casser inutilement les anciens call sites battle directs ;
  /// - l’assertion arrête donc tôt les usages invalides en debug/test ;
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le contournement trivial par sous-classe externe disparaît ;
  /// - on garde en plus un getter validé, car un objet battle incohérent peut
  ///   encore apparaître via un futur mauvais refactor interne ;
  /// - le moteur garde enfin sa propre validation défensive au moment exact où
  ///   il consomme le ratio critique ; cette dernière garde reste une défense
  ///   en profondeur, pas la preuve principale du contrat public.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError(
        'BattleMoveData critRatio must be >= 1; got $_critRatio.',
      );
    }
    return _critRatio;
  }

  /// Effet battle minimal de statut majeur si le bridge runtime l'a autorisé.
  ///
  /// Ce champ reste volontairement simple :
  /// - pas de liste générique d'effets battle ;
  /// - pas de volatile status ;
  /// - pas de payload de scope, car le bridge BE7 ne laisse passer que
  ///   `targetScope: target`.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par le move dans le sous-ensemble BE8.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// true si ce move peut percer une protection active BE8.
  final bool breaksProtect;

  /// true si ce move demande ensuite un tour de recharge.
  final bool requiresRecharge;

  /// Payload battle minimal d'un move à charge sur deux tours.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;
}

~~~~

### `packages/map_battle/lib/src/battle_state.dart`

~~~~dart
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Phase du combat.
///
/// Représente l'état actuel du cycle de combat.
enum BattlePhase {
  /// En attente du choix du joueur.
  ///
  /// C'est la phase normale entre les tours.
  /// Le runtime doit appeler [BattleSession.getAvailableChoices()] pour
  /// afficher les options au joueur.
  playerChoice,

  /// Résolution en cours.
  ///
  /// Phase transitoire pendant laquelle le tour est en cours de résolution.
  /// Le runtime ne doit pas permettre de nouveaux choix pendant cette phase.
  resolving,

  /// Combat terminé.
  ///
  /// [BattleState.outcome] est non-null et contient le résultat final.
  /// Le runtime doit appeler `_onBattleFinished(outcome)` pour revenir à l'overworld.
  finished,
}

/// État immutable d'un combat.
///
/// Ce modèle représente l'état complet d'un combat à un instant donné.
/// Il est immutable : toutes les méthodes de modification retournent un nouvel état.
///
/// Invariants :
/// - Si [phase] == [BattlePhase.finished], alors [outcome] est non-null.
/// - Si [phase] != [BattlePhase.finished], alors [outcome] est null.
/// - [player.currentHp] est toujours entre 0 et [player.maxHp].
/// - [enemy.currentHp] est toujours entre 0 et [enemy.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  /// [player] - Le combattant joueur.
  /// [enemy] - Le combattant adverse.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  const BattleState({
    required this.phase,
    required this.player,
    required this.enemy,
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  });

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Le combattant joueur.
  final BattleCombatant player;

  /// Le combattant adverse.
  final BattleCombatant enemy;

  /// État de champ observable du combat.
  ///
  /// BE9 le porte directement dans `BattleState` pour éviter un nouveau
  /// mensonge :
  /// - la météo et Trick Room modifient maintenant réellement le moteur ;
  /// - ils ne doivent donc pas vivre comme un détail caché de résolution ;
  /// - le runtime et les tests peuvent relire cet état sans introspection
  ///   privée de `BattleSession`.
  final BattleFieldState field;

  /// Le résultat du tour en cours.
  ///
  /// Null si aucun tour n'est en cours (phase [playerChoice] ou [finished]).
  final BattleTurnResult? currentTurn;

  /// Le résultat final du combat.
  ///
  /// Non-null uniquement si [phase] == [BattlePhase.finished].
  final BattleOutcome? outcome;

  /// true si le combat est terminé.
  ///
  /// Raccourci pour `phase == BattlePhase.finished`.
  bool get isFinished => phase == BattlePhase.finished;
}

/// Combattant en combat.
///
/// Représente un Pokémon avec ses PV courants.
/// Immutable : utiliser [withDamage] pour créer une copie avec des PV modifiés.
///
/// Invariants :
/// - [currentHp] est toujours entre 0 et [maxHp].
/// - [isFainted] est true si et seulement si [currentHp] <= 0.
class BattleCombatant {
  /// Crée un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce.
  /// [level] - Le niveau.
  /// [currentHp] - Les PV courants.
  /// [maxHp] - Les PV maximum.
  /// [stats] - Snapshot résolu des stats non-HP.
  /// [typing] - Typing battle minimal si connu.
  /// [majorStatus] - Statut majeur actuellement porté si le combattant en a un.
  /// [volatileState] - Sous-état volatile local BE8 (`protect`, recharge,
  ///   charge en attente).
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  /// [moves] - La liste des attaques disponibles.
  const BattleCombatant({
    required this.speciesId,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.abilityId = 'unknown',
    required this.moves,
    this.statStages = const BattleStatStages(),
  });

  /// L'identifiant de l'espèce.
  final String speciesId;

  /// Le niveau.
  final int level;

  /// Les PV courants.
  final int currentHp;

  /// Les PV maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP.
  ///
  /// BE2 le transporte jusqu'à l'état battle pour que :
  /// - les moves physiques opposent enfin attaque vs défense ;
  /// - les moves spéciaux opposent enfin spécial vs spécial défense ;
  /// - `speed` survive au handoff jusqu'au moteur.
  ///
  /// BE3 commence ensuite à la consommer réellement pour l'ordre d'action,
  /// sans pour autant ouvrir toute une queue générique ni un système de
  /// précision / critique / résiduels.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le setup le fournit.
  ///
  /// BE5 en a besoin pour fermer le trou où `type` était encore décoratif :
  /// - STAB dépend du typing de l'attaquant ;
  /// - résistances/faiblesses/immunités dépendent du typing du défenseur.
  ///
  /// Compatibilité résiduelle assumée :
  /// - un vieux setup direct `map_battle` peut encore laisser ce champ absent ;
  /// - dans ce cas, le moteur reste neutre sur la couche type au lieu de
  ///   fabriquer un typing par défaut qui mentirait davantage.
  final BattleTypingSnapshot? typing;

  /// Statut majeur actuellement porté par ce combattant.
  ///
  /// BE7 garde cet état volontairement étroit :
  /// - `null` signifie "aucun statut majeur" ;
  /// - sinon on porte uniquement `par`, `brn`, `psn` ou `tox` ;
  /// - il n'y a toujours ni volatiles génériques, ni `slp`, ni `frz`.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local strictement borné à BE8.
  ///
  /// On évite volontairement un conteneur générique :
  /// - `protectActive` pour la fenêtre de protection du tour courant ;
  /// - `mustRecharge` pour le tour perdu suivant certains moves ;
  /// - `pendingCharge` pour la deuxième moitié d'un move à charge.
  final BattleVolatileState volatileState;

  /// L'ability réellement résolue pour ce combattant.
  ///
  /// Le moteur lot 13 n'en tire toujours aucun calcul de combat. On la transporte
  /// néanmoins jusqu'à l'issue finale pour permettre au runtime de persister un
  /// Pokémon capturé à partir du vrai ennemi engagé, sans données inventées.
  final String abilityId;

  /// La liste des attaques disponibles.
  ///
  /// À partir de BE4, les moves battle transportent aussi leur PP courant :
  /// - la liste n'est donc plus seulement descriptive ;
  /// - elle porte un vrai petit état mutable-mais-immutable du point de vue
  ///   des copies de session ;
  /// - on n'ouvre toujours pas de write-back runtime des PP hors combat.
  final List<BattleMove> moves;

  /// Étages de stats actuellement appliqués à ce combattant.
  ///
  /// M8 reste volontairement borné :
  /// - on ne porte que les stats utiles au petit sous-ensemble réellement
  ///   exécutable ;
  /// - BE3 ajoute `speed` parce qu'elle devient enfin une vraie donnée moteur
  ///   pour l'ordre d'action ;
  /// - les autres mécaniques (status, weather, précision, ordre d'action
  ///   complet, etc.) restent hors scope.
  final BattleStatStages statStages;

  /// true si le combattant est K.O.
  ///
  /// Un combattant est K.O. si ses PV courants sont <= 0.
  bool get isFainted => currentHp <= 0;

  /// Crée une copie de ce combattant avec des dégâts appliqués.
  ///
  /// [damage] - La quantité de dégâts à appliquer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withDamage(int damage) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des PV restaurés.
  ///
  /// [healAmount] - La quantité de PV à restaurer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withHeal(int healAmount) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: (currentHp + healAmount).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des changements d'étages appliqués.
  ///
  /// Les étages sont toujours clampés dans la plage canonique minimale `[-6, 6]`.
  /// M8 ne gère ici que le sous-ensemble de stats réellement exploité par le
  /// moteur battle enrichi.
  BattleCombatant withAppliedStageChanges(
    List<BattleStatStageChange> changes,
  ) {
    if (changes.isEmpty) {
      return this;
    }
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages.apply(changes),
    );
  }

  /// Crée une copie avec un slot move remplacé.
  ///
  /// BE4 évite ici une sur-architecture :
  /// - pas de nouveau sous-état `MoveState` parallèle ;
  /// - pas de map indexée future-proof ;
  /// - juste le plus petit helper honnête pour décrémenter les PP d'un slot.
  BattleCombatant withUpdatedMoveAt(int index, BattleMove updatedMove) {
    if (index < 0 || index >= moves.length) {
      throw RangeError.index(index, moves, 'index');
    }

    final updatedMoves = List<BattleMove>.of(moves);
    updatedMoves[index] = updatedMove;
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: List<BattleMove>.unmodifiable(updatedMoves),
      statStages: statStages,
    );
  }

  /// Crée une copie avec un statut majeur mis à jour.
  ///
  /// Ce helper garde la transition d'état locale et lisible :
  /// - pas de builder parallèle de combattant ;
  /// - pas de mutation silencieuse d'un objet immutable ;
  /// - juste la plus petite brique utile pour `applyStatus`, la paralysie et
  ///   les résiduels de fin de tour.
  BattleCombatant withMajorStatus(BattleMajorStatusState? updatedStatus) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: updatedStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie avec un sous-état volatile mis à jour.
  ///
  /// BE8 garde cette transition locale et lisible :
  /// - pas de mutation silencieuse ;
  /// - pas de builder parallèle ;
  /// - juste le plus petit helper immutable utile pour `Protect`, la recharge
  ///   et les moves à charge.
  BattleCombatant withVolatileState(BattleVolatileState updatedVolatileState) {
    return BattleCombatant(
      speciesId: speciesId,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: updatedVolatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }
}

/// Étages de stats utilisables par le moteur battle MVP enrichi.
///
/// On évite volontairement une structure générique "Map<Stat, int>" :
/// - le moteur n'a besoin que d'un petit sous-ensemble ;
/// - cette forme garde des accès simples et des invariants lisibles ;
/// - elle évite d'ouvrir de faux besoins "future-proof" trop tôt.
class BattleStatStages {
  const BattleStatStages({
    this.attack = 0,
    this.defense = 0,
    this.specialAttack = 0,
    this.specialDefense = 0,
    this.speed = 0,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  /// Retourne une copie avec les changements demandés appliqués.
  BattleStatStages apply(List<BattleStatStageChange> changes) {
    var updated = this;
    for (final change in changes) {
      updated = updated._applyOne(change);
    }
    return updated;
  }

  BattleStatStages _applyOne(BattleStatStageChange change) {
    switch (change.stat) {
      case BattleStatId.attack:
        return BattleStatStages(
          attack: _clampStage(attack + change.stages),
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.defense:
        return BattleStatStages(
          attack: attack,
          defense: _clampStage(defense + change.stages),
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialAttack:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: _clampStage(specialAttack + change.stages),
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialDefense:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: _clampStage(specialDefense + change.stages),
          speed: speed,
        );
      case BattleStatId.speed:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: _clampStage(speed + change.stages),
        );
    }
  }

  /// Retourne le multiplicateur utilisé par le calcul de dégâts MVP enrichi.
  ///
  /// On reprend la table canonique simplifiée des stages Pokémon :
  /// - stage 0 => 1.0
  /// - stage +1 => 1.5
  /// - stage +2 => 2.0
  /// - stage -1 => 2/3
  /// etc.
  ///
  /// Cela suffit pour rendre les boosts/débuffs battle réellement visibles,
  /// sans ouvrir les vraies stats détaillées du moteur complet.
  double multiplierFor(BattleStatId stat) {
    final stage = switch (stat) {
      BattleStatId.attack => attack,
      BattleStatId.defense => defense,
      BattleStatId.specialAttack => specialAttack,
      BattleStatId.specialDefense => specialDefense,
      BattleStatId.speed => speed,
    };
    if (stage >= 0) {
      return (2 + stage) / 2;
    }
    return 2 / (2 - stage);
  }

  int _clampStage(int value) => value.clamp(-6, 6);
}

~~~~

### `packages/map_battle/test/battle_field_test.dart`

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

~~~~

### `packages/map_battle/test/battle_session_test.dart`

~~~~dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _neutralBattleStats = BattleStatsSnapshot(
  attack: 50,
  defense: 50,
  specialAttack: 50,
  specialDefense: 50,
  speed: 50,
);

void main() {
  group('BattleSession', () {
    // Helper pour créer un setup de test
    BattleSetup createTestSetup({
      bool isTrainerBattle = false,
      String? trainerId,
      bool allowCapture = false,
    }) {
      return BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            BattleMoveData(id: 'scratch', name: 'Griffe', power: 4),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: isTrainerBattle,
        trainerId: trainerId,
        allowCapture: allowCapture,
      );
    }

    test('createBattleSession creates session with playerChoice phase', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      expect(session.state.phase, equals(BattlePhase.playerChoice));
      expect(session.state.player.currentHp, equals(20)); // PV pleins
      expect(session.state.enemy.currentHp, equals(25)); // PV pleins
      expect(session.state.outcome, isNull);
      expect(session.state.isFinished, isFalse);
    });

    test('createBattleSession creates trainer battle with trainerId', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      expect(session.setup.isTrainerBattle, isTrue);
      expect(session.setup.trainerId, equals('gym_leader_1'));
    });

    test('createBattleSession respects currentHp when provided by runtime', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          currentHp: 7,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          currentHp: 11,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.currentHp, equals(7));
      expect(session.state.enemy.currentHp, equals(11));
    });

    test(
        'createBattleSession preserves the additional honest battle contract fields transported by BE1 through BE9',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(primaryType: 'electric'),
          volatileState: const BattleVolatileState(
            mustRecharge: true,
          ),
          moves: const [
            BattleMoveData(
              id: 'protect',
              name: 'Protect',
              power: 0,
              type: 'normal',
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
              accuracy: BattleMoveAccuracy.alwaysHits(),
              pp: 10,
              currentPp: 7,
              priority: 1,
              critRatio: 2,
              selfVolatileStatus: BattleVolatileStatusId.protect,
            ),
            BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              type: 'normal',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 5,
              currentPp: 3,
              requiresRecharge: true,
            ),
            BattleMoveData(
              id: 'solar_beam',
              name: 'Solar Beam',
              power: 120,
              type: 'grass',
              category: BattleMoveCategory.special,
              target: BattleMoveTarget.opponent,
              pp: 10,
              currentPp: 9,
              chargeThenStrikeEffect: BattleChargeThenStrikeEffect(
                chargeStateId: 'solar_charge',
              ),
            ),
            BattleMoveData(
              id: 'feint',
              name: 'Feint',
              power: 30,
              type: 'normal',
              category: BattleMoveCategory.physical,
              target: BattleMoveTarget.opponent,
              breaksProtect: true,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          typing: const BattleTypingSnapshot(
            primaryType: 'water',
            secondaryType: 'ice',
          ),
          volatileState: const BattleVolatileState(
            pendingCharge: BattlePendingChargeState(
              moveIndex: 0,
              moveId: 'tackle',
              chargeStateId: 'stored_charge',
            ),
          ),
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
        fieldState: const BattleFieldState(
          weather: BattleWeatherState(
            id: BattleWeatherId.rain,
            remainingTurns: 3,
          ),
          pseudoWeather: BattlePseudoWeatherState(
            id: BattlePseudoWeatherId.trickRoom,
            remainingTurns: 2,
          ),
        ),
      );

      final session = createBattleSession(setup);
      final protect = session.state.player.moves[0];
      final hyperBeam = session.state.player.moves[1];
      final solarBeam = session.state.player.moves[2];
      final feint = session.state.player.moves[3];
      final playerTyping = session.state.player.typing!;
      final enemyTyping = session.state.enemy.typing!;

      expect(protect.type, equals('normal'));
      expect(protect.category, equals(BattleMoveCategory.status));
      expect(protect.target, equals(BattleMoveTarget.self));
      expect(protect.accuracy.kind, equals(BattleMoveAccuracyKind.alwaysHits));
      expect(protect.pp, equals(10));
      expect(protect.currentPp, equals(7));
      expect(protect.priority, equals(1));
      expect(protect.critRatio, equals(2));
      expect(
        protect.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(hyperBeam.requiresRecharge, isTrue);
      expect(solarBeam.chargeThenStrikeEffect?.chargeStateId,
          equals('solar_charge'));
      expect(feint.breaksProtect, isTrue);
      expect(playerTyping.primaryType, equals('electric'));
      expect(playerTyping.secondaryType, isNull);
      expect(enemyTyping.primaryType, equals('water'));
      expect(enemyTyping.secondaryType, equals('ice'));
      expect(session.state.player.volatileState.mustRecharge, isTrue);
      expect(
        session.state.enemy.volatileState.pendingCharge?.moveId,
        equals('tackle'),
      );
      expect(session.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(session.state.field.weather?.remainingTurns, equals(3));
      expect(
        session.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(session.state.field.pseudoWeather?.remainingTurns, equals(2));
    });

    test(
        'createBattleSession preserves an explicit major status seed and move status effect',
        () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          majorStatus: const BattleMajorStatusState.brn(),
          moves: const [
            BattleMoveData(
              id: 'thunder_wave',
              name: 'Thunder Wave',
              power: 0,
              category: BattleMoveCategory.status,
              majorStatusEffect: BattleMoveMajorStatusEffect(
                status: BattleMajorStatusId.par,
              ),
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );

      final session = createBattleSession(setup);

      expect(session.state.player.majorStatus?.id,
          equals(BattleMajorStatusId.brn));
      expect(
        session.state.player.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test('BattleMoveData rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMoveData(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMove rejects an invalid crit ratio in debug builds', () {
      expect(
        () => BattleMove(
          id: 'slash',
          name: 'Slash',
          power: 50,
          critRatio: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('BattleMoveData keeps a valid crit ratio unchanged', () {
      // Mini-fix BE6-2 :
      // - on supprime les faux tests qui contournaient le contrat par héritage ;
      // - le vrai contrat public doit maintenant être évalué tel qu'il est
      //   réellement exposé aux call sites : un DTO final, `const`, typé ;
      // - ce test vérifie simplement qu'une valeur valide reste stable.
      const move = BattleMoveData(
        id: 'slash',
        name: 'Slash',
        power: 50,
        critRatio: 2,
      );

      expect(move.critRatio, equals(2));
    });

    test('BattleMove.withConsumedPp preserves a valid crit ratio', () {
      // Ce test remplace honnêtement l'ancien scénario artificiel :
      // - on ne forge plus un move malformé via override ;
      // - on vérifie que le vrai contrat public battle conserve `critRatio`
      //   pendant une transition d'état normale du moteur.
      const move = BattleMove(
        id: 'slash',
        name: 'Slash',
        power: 50,
        pp: 10,
        currentPp: 3,
        critRatio: 3,
      );

      final consumed = move.withConsumedPp();

      expect(consumed.critRatio, equals(3));
      expect(consumed.currentPp, equals(2));
    });

    test('getAvailableChoices hides fight choices whose currentPp is zero', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
            BattleMoveData(
              id: 'scratch',
              name: 'Griffe',
              power: 4,
              pp: 10,
              currentPp: 3,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();
      final fightChoices =
          choices.whereType<PlayerBattleChoiceFight>().toList();

      expect(fightChoices, hasLength(1));
      expect(fightChoices.single.moveIndex, equals(1));
    });

    test('forcing a move with zero PP is rejected explicitly', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(
              id: 'tackle',
              name: 'Charge',
              power: 5,
              pp: 10,
              currentPp: 0,
            ),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 25,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      expect(
        () => session.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('n’a plus de PP'),
          ),
        ),
      );
    });

    test('getAvailableChoices returns fight choices + run in wild battle', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      // 2 attaques + 1 fuite
      expect(choices.length, equals(3));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices exposes capture in wild battle when allowed', () {
      final setup = createTestSetup(allowCapture: true);
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(4));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices[2], isA<PlayerBattleChoiceCapture>());
      expect(choices[3], isA<PlayerBattleChoiceRun>());
    });

    test('getAvailableChoices does not expose run in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.length, equals(2));
      expect(choices[0], isA<PlayerBattleChoiceFight>());
      expect(choices[1], isA<PlayerBattleChoiceFight>());
      expect(choices.whereType<PlayerBattleChoiceRun>(), isEmpty);
    });

    test('getAvailableChoices does not expose capture in trainer battle', () {
      final setup = createTestSetup(
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
        allowCapture: true,
      );
      final session = createBattleSession(setup);

      final choices = session.getAvailableChoices();

      expect(choices.whereType<PlayerBattleChoiceCapture>(), isEmpty);
    });

    test('getAvailableChoices exposes Continue for a forced recharge turn', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'pikachu',
            level: 5,
            maxHp: 20,
            stats: _neutralBattleStats,
            volatileState: const BattleVolatileState(
              mustRecharge: true,
            ),
            moves: const [
              BattleMoveData(
                id: 'hyper_beam',
                name: 'Hyper Beam',
                power: 150,
                requiresRecharge: true,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'lapras',
            level: 5,
            maxHp: 25,
            stats: _neutralBattleStats,
            moves: const [
              BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final choices = session.getAvailableChoices();

      expect(choices, hasLength(1));
      expect(choices.single, isA<PlayerBattleChoiceContinue>());
    });

    test('applyChoice with fight resolves turn and damages enemy', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque (power=5)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Avec le contract de dégâts BE2, le move passe maintenant par les
      // vraies stats résolues au lieu de faire `damage = power`.
      expect(newSession.state.enemy.currentHp, equals(23));
      expect(newSession.state.currentTurn, isNotNull);
      expect(newSession.state.currentTurn!.executions.length, greaterThan(0));
    });

    test('applyChoice with fight resolves turn and damages player', () {
      final setup = createTestSetup();
      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      // Joueur utilise la première attaque
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Même logique pour la contre-attaque : on attend désormais un dégât
      // déterministe issu de la formule BE2, pas la puissance brute.
      expect(newSession.state.player.currentHp, equals(18));
    });

    test('KO enemy results in victory', () {
      // Créer un ennemi avec peu de PV
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 100,
          maxHp: 20,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'mega-punch', name: 'Mega-Poing', power: 25),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // PV max = 20, donc 1 hit KO
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Mega-Punch (power=25, one-shot)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.state.enemy.isFainted, isTrue);
    });

    test('KO player results in defeat', () {
      // Créer un joueur avec peu de PV face à un ennemi puissant
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 5, // Très peu de PV
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psychic', name: 'Psyko', power: 10),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      final session = createBattleSession(setup);

      // Joueur utilise Growl (power=0, ne fait rien)
      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome, isNotNull);
      expect(newSession.state.outcome!.isDefeat, isTrue);
      expect(newSession.state.player.isFainted, isTrue);
    });

    test('trainer battle victory outcome is compatible with marking', () {
      // Créer un setup où le joueur gagne en 1 coup
      final oneHitSetup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'mewtwo',
          level: 100,
          maxHp: 100,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'psystrike', name: 'Frapp Psy', power: 50),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 20, // One-shot
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 5),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'gym_leader_1',
      );
      final session = createBattleSession(oneHitSetup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(newSession.state.isFinished, isTrue);
      expect(newSession.state.outcome!.isVictory, isTrue);
      expect(newSession.setup.trainerId, equals('gym_leader_1'));
      // Le runtime peut maintenant marquer : 'trainer_defeated:gym_leader_1'
    });

    test('applyChoice returns new session (immutable)', () {
      final setup = createTestSetup();
      final session = createBattleSession(setup);

      final newSession = session.applyChoice(const PlayerBattleChoiceFight(0));

      // Vérifier que c'est une nouvelle instance
      expect(identical(session, newSession), isFalse);
      expect(identical(session.state, newSession.state), isFalse);
    });

    test('multiple turns until one combatant faints', () {
      final setup = BattleSetup(
        playerPokemon: BattleCombatantData(
          speciesId: 'pikachu',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        enemyPokemon: BattleCombatantData(
          speciesId: 'lapras',
          level: 5,
          maxHp: 30,
          stats: _neutralBattleStats,
          moves: const [
            BattleMoveData(id: 'tackle', name: 'Charge', power: 100),
          ],
        ),
        isTrainerBattle: false,
        trainerId: null,
      );
      var session = createBattleSession(
        setup,
        rng: BattleScriptedRng(List<int>.filled(6, 2)),
      );

      // Tour 1
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse); // Les deux sont encore vivants
      expect(session.state.player.currentHp, equals(20)); // 30 - 10
      expect(session.state.enemy.currentHp, equals(20)); // 30 - 10

      // Tour 2
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isFalse);
      expect(session.state.player.currentHp, equals(10)); // 20 - 10
      expect(session.state.enemy.currentHp, equals(10)); // 20 - 10

      // Tour 3
      session = session.applyChoice(const PlayerBattleChoiceFight(0));
      expect(session.state.isFinished, isTrue); // Les deux sont à 0 PV
      // Le joueur joue en premier, donc l'ennemi meurt en premier → victoire
      expect(session.state.outcome!.isVictory, isTrue);
    });
  });
}

~~~~

### `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`

~~~~dart
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'runtime_battle_setup_exception.dart';

/// Bridge runtime -> battle pour un sous-ensemble honnête de `PokemonMove`.
///
/// Frontière volontaire de M8 :
/// - le loader runtime charge le canonique sans faire de policy d'exécution ;
/// - ce bridge décide si un move canonique peut être projeté honnêtement vers
///   le moteur battle MVP actuel ;
/// - `map_battle` exécute ensuite uniquement ce petit contrat battle enrichi.
///
/// Le but n'est pas de "supporter un peu tout" :
/// - on garde le standard damage flow ;
/// - on supporte `modifyStats` déterministe pour un petit sous-ensemble utile ;
/// - on refuse explicitement le reste.
///
/// BE1 durcit ce bridge sur un autre axe :
/// - certaines dimensions canoniques étaient encore perdues silencieusement ;
/// - on transporte maintenant le petit supplément de contrat battle qui évite
///   cette perte (`type`, `target`, `pp`) ;
/// - et on refuse explicitement les dimensions non neutres qui resteraient
///   encore mensongères sans nouvelle couche moteur (`priority`, cibles hors
///   1v1 simple honnête).
///
/// BE3 recadre ensuite ce point :
/// - `priority` n'est plus refusée, parce que `map_battle` sait enfin
///   ordonner honnêtement deux actions `Fight` ;
/// - `speed` stage devient également supportée pour ce même besoin ;
/// - puis BE4 ouvre enfin l'accuracy battle minimale et les PP réels ;
/// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
/// - puis BE7 ouvre un petit sous-ensemble `applyStatus` pour les statuts
///   majeurs `par`, `brn`, `psn`, `tox` ;
/// - puis BE8 ouvre seulement quelques volatiles utiles strictement bornés :
///   `protect`, `breakProtect`, `requireRecharge`, `chargeThenStrike` ;
/// - puis BE9 ouvre seulement un petit sous-ensemble field réellement
///   consommé : `raindance`, `sandstorm`, `trickroom` ;
/// - le reste reste explicitement hors scope et donc refusé.
class RuntimeBattleMoveBridge {
  const RuntimeBattleMoveBridge();

  /// Projette un move canonique vers le contrat `BattleMoveData`.
  ///
  /// Le refus est explicite et descriptif :
  /// - pas de fallback silencieux ;
  /// - pas de `power: 0` mensonger pour un move que le moteur n'exécute pas ;
  /// - pas de mutation opportuniste de `engineSupportLevel`.
  BattleMoveData toBattleMoveData({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    _ensureEngineSupportLevelAllowsBridge(
      move: move,
      combatantLabel: combatantLabel,
    );
    final target = _translateSupportedTarget(
      move: move,
      combatantLabel: combatantLabel,
    );
    final type = _translateType(
      move: move,
      combatantLabel: combatantLabel,
    );
    final accuracy = _translateAccuracy(move.accuracy);

    final selfChanges = <BattleStatStageChange>[];
    final targetChanges = <BattleStatStageChange>[];
    BattleMoveMajorStatusEffect? majorStatusEffect;
    BattleVolatileStatusId? selfVolatileStatus;
    BattleWeatherId? weatherEffect;
    BattlePseudoWeatherId? pseudoWeatherEffect;
    var breaksProtect = false;
    var requiresRecharge = false;
    BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

    for (final effect in move.effects) {
      effect.map(
        fixedDamage: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:fixed_damage',
        ),
        multiHit: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:multi_hit',
        ),
        applyStatus: (effect) {
          if (majorStatusEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_apply_status_effects_not_supported',
            );
          }

          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_apply_status_target:${target.name}',
            );
          }

          if (effect.chance case final chance?) {
            if (chance < 1 || chance > 100) {
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit: 'invalid_apply_status_chance:$chance',
              );
            }
          }

          majorStatusEffect = BattleMoveMajorStatusEffect(
            status: _translateSupportedMajorStatus(
              move: move,
              combatantLabel: combatantLabel,
              statusId: effect.statusId,
            ),
            chancePercent: effect.chance,
          );
        },
        applyVolatileStatus: (effect) {
          // BE8 n'ouvre surtout pas tout `applyVolatileStatus`.
          // Le bridge accepte uniquement le plus petit seam devenu exécutable :
          // - `protect` auto-appliqué au lanceur ;
          // - déterministe ;
          // - aucune autre taxonomie de volatile.
          if (selfVolatileStatus != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'multiple_apply_volatile_status_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_apply_volatile_status_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_apply_volatile_status_not_supported',
            );
          }

          selfVolatileStatus = _translateSupportedSelfVolatileStatus(
            move: move,
            combatantLabel: combatantLabel,
            volatileStatusId: effect.volatileStatusId,
          );
        },
        modifyStats: (effect) {
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_modify_stats_not_supported',
            );
          }
          if (effect.stageChanges.isEmpty) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'empty_modify_stats_not_supported',
            );
          }

          final translated = effect.stageChanges
              .map(
                (change) => _translateStageChange(
                  change: change,
                  move: move,
                  combatantLabel: combatantLabel,
                ),
              )
              .toList(growable: false);

          switch (effect.targetScope) {
            case PokemonMoveEffectTargetScope.self:
              selfChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.target:
              targetChanges.addAll(translated);
            case PokemonMoveEffectTargetScope.field:
            case PokemonMoveEffectTargetScope.allySide:
            case PokemonMoveEffectTargetScope.foeSide:
            case PokemonMoveEffectTargetScope.slot:
              _rejectMove(
                move: move,
                combatantLabel: combatantLabel,
                bridgeLimit:
                    'unsupported_modify_stats_scope:${effect.targetScope.name}',
              );
          }
        },
        heal: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:heal',
        ),
        drain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:drain',
        ),
        recoil: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:recoil',
        ),
        setWeather: (effect) {
          if (weatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_weather_move_shape',
            );
          }
          weatherEffect = _translateSupportedWeather(
            move: move,
            combatantLabel: combatantLabel,
            weatherId: effect.weatherId,
          );
        },
        setTerrain: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_terrain',
        ),
        setPseudoWeather: (effect) {
          if (pseudoWeatherEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_set_pseudo_weather_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.field) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_set_pseudo_weather_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_set_pseudo_weather_not_supported',
            );
          }
          if (move.usesStandardDamageFlow) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_set_pseudo_weather_move_shape',
            );
          }
          pseudoWeatherEffect = _translateSupportedPseudoWeather(
            move: move,
            combatantLabel: combatantLabel,
            pseudoWeatherId: effect.pseudoWeatherId,
          );
        },
        selfSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:self_switch',
        ),
        forceSwitch: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:force_switch',
        ),
        breakProtect: (effect) {
          if (breaksProtect) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_break_protect_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.target) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_break_protect_scope:${effect.targetScope.name}',
            );
          }
          if (target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_break_protect_target:${target.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_break_protect_not_supported',
            );
          }
          breaksProtect = true;
        },
        requireRecharge: (effect) {
          if (requiresRecharge) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_require_recharge_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_require_recharge_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_require_recharge_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_require_recharge_move_shape',
            );
          }
          requiresRecharge = true;
        },
        chargeThenStrike: (effect) {
          if (chargeThenStrikeEffect != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'multiple_charge_then_strike_effects_not_supported',
            );
          }
          if (effect.targetScope != PokemonMoveEffectTargetScope.self) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit:
                  'unsupported_charge_then_strike_scope:${effect.targetScope.name}',
            );
          }
          if (effect.chance != null) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'probabilistic_charge_then_strike_not_supported',
            );
          }
          if (!move.usesStandardDamageFlow ||
              target != BattleMoveTarget.opponent) {
            _rejectMove(
              move: move,
              combatantLabel: combatantLabel,
              bridgeLimit: 'unsupported_charge_then_strike_move_shape',
            );
          }
          chargeThenStrikeEffect = BattleChargeThenStrikeEffect(
            chargeStateId: _normalizeOptionalId(effect.chargeStateId),
          );
        },
        setSideCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_side_condition',
        ),
        setSlotCondition: (_) => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_effect_kind:set_slot_condition',
        ),
      );
    }

    // BE8 revendique un sous-ensemble exact, pas une "approximation large".
    // On refuse donc explicitement les combinaisons d'effets qui ne font pas
    // partie du petit contrat local ouvert par ce lot, même si chaque brique
    // isolée serait supportée séparément.
    if (requiresRecharge && chargeThenStrikeEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_charge_then_recharge',
      );
    }
    if ((weatherEffect != null || pseudoWeatherEffect != null) &&
        (majorStatusEffect != null ||
            selfVolatileStatus != null ||
            breaksProtect ||
            requiresRecharge ||
            chargeThenStrikeEffect != null ||
            selfChanges.isNotEmpty ||
            targetChanges.isNotEmpty)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_combined_field_effect_move',
      );
    }
    if (weatherEffect != null && pseudoWeatherEffect != null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'multiple_field_effect_kinds_not_supported',
      );
    }

    // Un move battle exécutable doit avoir au moins un chemin d'exécution
    // réel pour le moteur actuel :
    // - soit des dégâts standards ;
    // - soit des changements d'étages de stats déterministes ;
    // - soit un effet `applyStatus` BE7 réellement supporté ;
    // - soit une pose de champ réellement consommée en BE9 ;
    // - soit une combinaison de ces chemins-là quand elle est explicitement
    //   autorisée plus haut.
    if (!move.usesStandardDamageFlow &&
        selfChanges.isEmpty &&
        targetChanges.isEmpty &&
        majorStatusEffect == null &&
        selfVolatileStatus == null &&
        weatherEffect == null &&
        pseudoWeatherEffect == null) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'no_supported_execution_path',
      );
    }

    // Le moteur battle actuel sait seulement :
    // - infliger des dégâts à l'adversaire actif ;
    // - ou appliquer des boosts/baisses déterministes sur `self` / target.
    //
    // Un move auto-ciblé qui ferait malgré tout des dégâts standards serait
    // donc encore projeté mensongèrement : `map_battle` le résoudrait contre
    // l'adversaire faute de vrai contrat "self damage".
    //
    // On préfère refuser explicitement ce cas tant qu'un lot ultérieur n'ouvre
    // pas une sémantique battle claire pour ce type d'exécution.
    if (move.usesStandardDamageFlow && target == BattleMoveTarget.self) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_standard_damage_target:self',
      );
    }

    return BattleMoveData(
      id: move.id,
      name: move.name,
      power: move.usesStandardDamageFlow ? move.basePower : 0,
      type: type,
      category: _translateCategory(move.category),
      target: target,
      accuracy: accuracy,
      pp: move.pp,
      priority: move.priority,
      critRatio: move.critRatio,
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      selfStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(selfChanges),
      targetStatStageChanges:
          List<BattleStatStageChange>.unmodifiable(targetChanges),
    );
  }

  void _ensureEngineSupportLevelAllowsBridge({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
            PokemonMoveEngineSupportLevel.structuredSupported ||
        _allowsStructuredPartialFieldMove(move)) {
      return;
    }
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'engine_support_level_not_bridgeable',
    );
  }

  BattleMoveAccuracy _translateAccuracy(PokemonMoveAccuracy accuracy) {
    return accuracy.map(
      percent: (accuracy) => BattleMoveAccuracy.percent(value: accuracy.value),
      alwaysHits: (_) => const BattleMoveAccuracy.alwaysHits(),
    );
  }

  String _translateType({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final normalizedType = move.type.trim().toLowerCase();
    if (normalizedType.isEmpty) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'invalid_type:empty',
      );
    }

    // Même règle qu'au chargement des espèces :
    // - la liste des types réellement supportés ne doit vivre qu'à un seul
    //   endroit ;
    // - le bridge réutilise donc `BattleTypeChart.supportedTypes` au lieu de
    //   maintenir une seconde liste locale ;
    // - cela permet de rejeter le move au bon seam runtime -> battle, avec
    //   une erreur actionnable, plutôt que de laisser `map_battle` exploser
    //   plus tard par `StateError`.
    if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
      _rejectMove(
        move: move,
        combatantLabel: combatantLabel,
        bridgeLimit: 'unsupported_type:$normalizedType',
      );
    }

    return normalizedType;
  }

  BattleMoveCategory _translateCategory(PokemonMoveCategory category) {
    return switch (category) {
      PokemonMoveCategory.physical => BattleMoveCategory.physical,
      PokemonMoveCategory.special => BattleMoveCategory.special,
      PokemonMoveCategory.status => BattleMoveCategory.status,
    };
  }

  BattleMoveTarget _translateSupportedTarget({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    // BE1 ne promet toujours pas un système de targeting complet.
    // En revanche, on peut déjà arrêter de perdre silencieusement l'intention
    // canonique quand elle reste honnête en 1v1 simple actif :
    // - `self` -> self ;
    // - `normal`, `adjacentFoe`, `allAdjacentFoes`, `randomNormal`
    //   -> opponent.
    //
    // Les autres formes (`all`, `allySide`, `foeSide`, etc.) exigent une
    // sémantique de terrain/sides/slots ou de multibattle absente aujourd'hui.
    if (_isPureFieldMoveCandidate(move)) {
      return switch (move.target) {
        // Recadrage BE9 après review :
        // - le sous-ensemble honnête réellement seedé dans ce repo pose la
        //   météo / Trick Room avec `target: all` ;
        // - accepter aussi `self` élargissait inutilement le contrat et
        //   laissait passer un faux field move malformé ;
        // - on garde donc un bridge strict au lieu d'une tolérance qui ne
        //   sert aucun cas réel confirmé par l'audit.
        PokemonMoveTarget.all => BattleMoveTarget.field,
        _ => _rejectMove(
            move: move,
            combatantLabel: combatantLabel,
            bridgeLimit: 'unsupported_field_target:${move.target.name}',
          ),
      };
    }

    return switch (move.target) {
      PokemonMoveTarget.self => BattleMoveTarget.self,
      PokemonMoveTarget.normal ||
      PokemonMoveTarget.adjacentFoe ||
      PokemonMoveTarget.allAdjacentFoes ||
      PokemonMoveTarget.randomNormal =>
        BattleMoveTarget.opponent,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_target:${move.target.name}',
        ),
    };
  }

  BattleStatStageChange _translateStageChange({
    required PokemonMoveStatStageChange change,
    required PokemonMove move,
    required String combatantLabel,
  }) {
    final stat = switch (change.stat) {
      PokemonMoveStatId.attack => BattleStatId.attack,
      PokemonMoveStatId.defense => BattleStatId.defense,
      PokemonMoveStatId.specialAttack => BattleStatId.specialAttack,
      PokemonMoveStatId.specialDefense => BattleStatId.specialDefense,
      // BE3 ouvre ici la plus petite extension honnête possible :
      // - `speed` stage devient enfin utile car le moteur ordonne désormais
      //   les deux actions `Fight` par vitesse effective ;
      // - on ne profite pas de cette ouverture pour accepter accuracy/evasion,
      //   qui resteraient mensongères sans hit pipeline réel.
      PokemonMoveStatId.speed => BattleStatId.speed,
      PokemonMoveStatId.accuracy => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
      PokemonMoveStatId.evasion => _rejectUnsupportedStat(
          move: move,
          combatantLabel: combatantLabel,
          stat: change.stat,
        ),
    };

    return BattleStatStageChange(
      stat: stat,
      stages: change.stages,
    );
  }

  BattleMajorStatusId _translateSupportedMajorStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String statusId,
  }) {
    final normalizedStatusId = statusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'par' => BattleMajorStatusId.par,
      'brn' => BattleMajorStatusId.brn,
      'psn' => BattleMajorStatusId.psn,
      'tox' => BattleMajorStatusId.tox,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_major_status:$normalizedStatusId',
        ),
    };
  }

  BattleVolatileStatusId _translateSupportedSelfVolatileStatus({
    required PokemonMove move,
    required String combatantLabel,
    required String volatileStatusId,
  }) {
    final normalizedStatusId = volatileStatusId.trim().toLowerCase();
    return switch (normalizedStatusId) {
      'protect' => BattleVolatileStatusId.protect,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_volatile_status:$normalizedStatusId',
        ),
    };
  }

  BattleWeatherId _translateSupportedWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String weatherId,
  }) {
    final normalizedWeatherId = weatherId.trim().toLowerCase();
    return switch (normalizedWeatherId) {
      'raindance' => BattleWeatherId.rain,
      'sandstorm' => BattleWeatherId.sandstorm,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_weather:$normalizedWeatherId',
        ),
    };
  }

  BattlePseudoWeatherId _translateSupportedPseudoWeather({
    required PokemonMove move,
    required String combatantLabel,
    required String pseudoWeatherId,
  }) {
    final normalizedPseudoWeatherId = pseudoWeatherId.trim().toLowerCase();
    return switch (normalizedPseudoWeatherId) {
      'trickroom' => BattlePseudoWeatherId.trickRoom,
      _ => _rejectMove(
          move: move,
          combatantLabel: combatantLabel,
          bridgeLimit: 'unsupported_pseudo_weather:$normalizedPseudoWeatherId',
        ),
    };
  }

  bool _isPureFieldMoveCandidate(PokemonMove move) {
    if (move.usesStandardDamageFlow) {
      return false;
    }
    if (move.effects.isEmpty) {
      return false;
    }
    return move.effects.every(
      (effect) => effect.map(
        fixedDamage: (_) => false,
        multiHit: (_) => false,
        applyStatus: (_) => false,
        applyVolatileStatus: (_) => false,
        modifyStats: (_) => false,
        heal: (_) => false,
        drain: (_) => false,
        recoil: (_) => false,
        setWeather: (_) => true,
        setTerrain: (_) => false,
        setPseudoWeather: (_) => true,
        selfSwitch: (_) => false,
        forceSwitch: (_) => false,
        breakProtect: (_) => false,
        requireRecharge: (_) => false,
        chargeThenStrike: (_) => false,
        setSideCondition: (_) => false,
        setSlotCondition: (_) => false,
      ),
    );
  }

  bool _allowsStructuredPartialFieldMove(PokemonMove move) {
    if (move.engineSupportLevel !=
        PokemonMoveEngineSupportLevel.structuredPartial) {
      return false;
    }
    if (!_isPureFieldMoveCandidate(move)) {
      return false;
    }

    // Recadrage BE9 :
    // - on n'ouvre pas globalement tous les moves `structuredPartial` ;
    // - on autorise uniquement les vieux catalogues qui marquaient encore
    //   `Trick Room` comme partiel faute de couche de champ/durée ;
    // - tout autre motif de partial support reste refusé par défaut.
    const allowedReasons = <String>{
      'unsupported_mechanic:turn_order_inversion',
      'unsupported_mechanic:condition',
      'showdown_callback:condition.durationCallback',
      'showdown_callback:condition.onFieldEnd',
      'showdown_callback:condition.onFieldRestart',
      'showdown_callback:condition.onFieldStart',
    };
    return move.unsupportedReasons.every(allowedReasons.contains);
  }

  String? _normalizeOptionalId(String? value) {
    if (value == null) {
      return null;
    }
    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }

  Never _rejectUnsupportedStat({
    required PokemonMove move,
    required String combatantLabel,
    required PokemonMoveStatId stat,
  }) {
    _rejectMove(
      move: move,
      combatantLabel: combatantLabel,
      bridgeLimit: 'unsupported_stat_stage:${stat.name}',
    );
  }

  Never _rejectMove({
    required PokemonMove move,
    required String combatantLabel,
    required String bridgeLimit,
  }) {
    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le bridge battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons, bridgeLimit=$bridgeLimit',
    );
  }
}

~~~~

### `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`

~~~~dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

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
    final choicesTitle = TextComponent(
      text: 'Que doit faire le joueur ?',
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
    _panel!.add(choicesTitle);

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

    // Afficher le résultat du tour si disponible
    _updateTurnResult();

    // Si le combat est fini, afficher le résultat
    if (newSession.state.isFinished) {
      _showOutcome(newSession.state.outcome!);
    } else {
      // Combat toujours en cours — maintenir la sélection cohérente
      // Clamper l'index si le nombre de choix a changé
      final choices = newSession.getAvailableChoices();
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

    // Construire le texte du résultat du tour
    final lines = <String>[];
    for (final execution in turnResult.executions) {
      final attacker = _combatantLabel(execution.attacker);
      lines.add(
          '$attacker utilise ${execution.move.name} → ${execution.damage} dégâts');
    }

    for (final event in turnResult.volatileEvents) {
      lines.add(_formatVolatileEvent(event));
    }

    for (final event in turnResult.fieldEvents) {
      lines.add(_formatFieldEvent(event));
    }

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
    final choices = _session.getAvailableChoices();
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
      final text = _getChoiceText(choice);
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
  String _getChoiceText(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Lit les moves depuis _session.state.player.moves — toujours à jour
      final move = _session.state.player.moves[choice.moveIndex];
      return '⚔ ${move.name} (Puissance: ${move.power})';
    } else if (choice is PlayerBattleChoiceContinue) {
      // BE8 ajoute des tours forcés honnêtes (recharge / libération d'un move
      // déjà chargé). Afficher `???` ici mentirait sur la surface joueur :
      // il ne choisit pas un nouveau move, il valide simplement la poursuite
      // de ce tour contraint par le moteur battle.
      final volatileState = _session.state.player.volatileState;
      if (volatileState.pendingCharge != null) {
        return 'Continuer (libérer la charge)';
      }
      if (volatileState.mustRecharge) {
        return 'Continuer (recharge)';
      }
      return 'Continuer';
    } else if (choice is PlayerBattleChoiceCapture) {
      return 'Capturer';
    } else if (choice is PlayerBattleChoiceRun) {
      return '🏃 Fuir';
    }
    return '???';
  }

  String _formatVolatileEvent(BattleVolatileEvent event) {
    final actor = _combatantLabel(event.actor);
    final target = event.target == null ? null : _combatantLabel(event.target!);

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

  String _formatFieldEvent(BattleFieldEvent event) {
    return switch (event.kind) {
      BattleFieldEventKind.weatherSet =>
        'Le champ passe à ${_weatherLabel(event.weather!)}',
      BattleFieldEventKind.weatherResidualDamage =>
        '${_combatantLabel(event.target!)} subit ${event.damage} dégâts de ${_weatherLabel(event.weather!)}',
      BattleFieldEventKind.weatherExpired =>
        '${_weatherLabel(event.weather!)} prend fin',
      BattleFieldEventKind.pseudoWeatherSet =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} devient actif',
      BattleFieldEventKind.pseudoWeatherCleared =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} est dissipé',
      BattleFieldEventKind.pseudoWeatherExpired =>
        '${_pseudoWeatherLabel(event.pseudoWeather!)} prend fin',
    };
  }

  String _combatantLabel(String combatantId) {
    return combatantId == 'player' ? 'Joueur' : 'Ennemi';
  }

  String _weatherLabel(BattleWeatherId weather) {
    return switch (weather) {
      BattleWeatherId.rain => 'la pluie',
      BattleWeatherId.sandstorm => 'la tempête de sable',
    };
  }

  String _pseudoWeatherLabel(BattlePseudoWeatherId pseudoWeather) {
    return switch (pseudoWeather) {
      BattlePseudoWeatherId.trickRoom => 'Trick Room',
    };
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
    return 'Joueur: ${_session.state.player.currentHp}/${_session.state.player.maxHp} PV';
  }

  /// Retourne le texte des PV de l'ennemi.
  ///
  /// Lit [_session] qui est toujours à jour grâce à updateState().
  String _getEnemyHpText() {
    return 'Ennemi: ${_session.state.enemy.currentHp}/${_session.state.enemy.maxHp} PV';
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

~~~~

### `packages/map_runtime/test/runtime_battle_combatant_seed_builder_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/runtime_battle_combatant_seed_builder.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleCombatantSeedBuilder', () {
    late Directory tempProjectRoot;
    const builder = RuntimeBattleCombatantSeedBuilder();
    const moveCatalogLoader = RuntimeMoveCatalogLoader();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_combatant_seed_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('builds a player combatant seed from explicit knownMoveIds', () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(
            hp: 31,
            attack: 31,
            specialAttack: 15,
            speed: 7,
          ),
          evs: PokemonStatSpread(
            hp: 8,
            attack: 12,
            specialAttack: 20,
            speed: 16,
          ),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      );

      expect(seed.speciesId, equals('sproutle'));
      expect(seed.level, equals(12));
      expect(seed.maxHp, equals(36));
      expect(seed.currentHp, equals(23));
      expect(seed.abilityId, equals('overgrow'));
      expect(seed.typing.primaryType, equals('grass'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.stats.attack, equals(20));
      expect(seed.stats.defense, equals(16));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(20));
      expect(seed.stats.speed, equals(17));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        seed.moves.first.targetStatStageChanges.single.stages,
        equals(-1),
      );
      expect(seed.moves[1].power, equals(45));
    });

    test('preserves the BE8 move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>[
            'protect',
            'hyper_beam',
            'solar_beam',
            'feint',
          ],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['protect', 'hyper_beam', 'solar_beam', 'feint']),
      );
      expect(
        seed.moves[0].selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
      expect(seed.moves[1].requiresRecharge, isTrue);
      expect(
        seed.moves[2].chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(seed.moves[3].breaksProtect, isTrue);
    });

    test(
        'preserves the BE9 field move subset through the combatant seed contract',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['rain_dance', 'sandstorm', 'trick_room'],
          currentHp: 23,
        ),
      );

      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['rain_dance', 'sandstorm', 'trick_room']),
      );
      expect(seed.moves[0].target, equals(BattleMoveTarget.field));
      expect(seed.moves[0].weatherEffect, equals(BattleWeatherId.rain));
      expect(seed.moves[1].target, equals(BattleMoveTarget.field));
      expect(seed.moves[1].weatherEffect, equals(BattleWeatherId.sandstorm));
      expect(seed.moves[2].target, equals(BattleMoveTarget.field));
      expect(
        seed.moves[2].pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(seed.moves[2].priority, equals(-7));
    });

    test(
        'derives player moves from the learnset, falls back to species id and keeps the last four unique moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'calm',
          abilityId: 'overgrow',
          level: 25,
          currentHp: 30,
        ),
      );

      // Le seam M7 doit conserver exactement la policy historique :
      // - concat starting/relearn/levelUp<=niveau ;
      // - unicité dans l'ordre d'apparition ;
      // - puis conservation des quatre derniers si la liste déborde.
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['growl', 'vine_whip', 'leer', 'razor_leaf']),
      );
    });

    test('builds a wild combatant seed from species and learnset data',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildWildCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(seed.speciesId, equals('sparkitten'));
      expect(seed.level, equals(10));
      expect(seed.currentHp, isNull);
      expect(seed.abilityId, equals('blaze'));
      expect(seed.typing.primaryType, equals('fire'));
      expect(seed.typing.secondaryType, isNull);
      expect(seed.maxHp, equals(27));
      expect(seed.stats.attack, equals(15));
      expect(seed.stats.defense, equals(13));
      expect(seed.stats.specialAttack, equals(17));
      expect(seed.stats.specialDefense, equals(15));
      expect(seed.stats.speed, equals(18));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
    });

    test('builds a trainer combatant seed from explicit trainer moves',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildTrainerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        teamMember: const ProjectTrainerPokemonEntry(
          speciesId: 'aquafi',
          level: 18,
          moves: <String>['water_gun', 'tail_whip'],
          heldItemId: 'mystic_water',
        ),
        trainerName: 'Ace Jules',
      );

      expect(seed.speciesId, equals('aquafi'));
      expect(seed.level, equals(18));
      expect(seed.abilityId, equals('torrent'));
      expect(seed.typing.primaryType, equals('water'));
      expect(seed.typing.secondaryType, equals('fairy'));
      expect(seed.stats.attack, equals(22));
      expect(seed.stats.defense, equals(28));
      expect(seed.stats.specialAttack, equals(23));
      expect(seed.stats.specialDefense, equals(28));
      expect(seed.stats.speed, equals(20));
      expect(
        seed.moves.map((move) => move.id).toList(growable: false),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test(
        'preserves the M5-bis gate and rejects a partially supported move during seed assembly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['growl', 'vine_whip'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=growl'),
              contains('engineSupportLevel=structuredPartial'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
              ),
            ),
          ),
        ),
      );
    });

    test('fails explicitly when a requested move is absent from the catalog',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      await expectLater(
        () => builder.buildPlayerCombatantSeed(
          projectRootDirectory: tempProjectRoot.path,
          pokemonConfig: _pokemonConfig(),
          movesCatalog: movesCatalog,
          playerPokemon: const PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'bold',
            abilityId: 'overgrow',
            level: 12,
            knownMoveIds: <String>['move_that_does_not_exist'],
            currentHp: 23,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'keeps a structured supported major status move once BE7 opens applyStatus honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['thunder_wave'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('thunder_wave'));
      expect(
        seed.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
    });

    test(
        'keeps a non-zero priority move once battle order consumes it honestly',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['quick_attack'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('quick_attack'));
      expect(seed.moves.single.priority, equals(1));
    });

    test('keeps a non-trivial accuracy move once battle owns the hit check',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['mud_slap'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('mud_slap'));
      expect(seed.moves.single.accuracy.kind,
          equals(BattleMoveAccuracyKind.percent));
      expect(seed.moves.single.accuracy.value, equals(85));
    });

    test(
        'keeps a non-neutral crit ratio once battle owns minimal critical hits',
        () async {
      await _writePokemonFixtures(tempProjectRoot);
      final movesCatalog = await moveCatalogLoader.load(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
      );

      final seed = await builder.buildPlayerCombatantSeed(
        projectRootDirectory: tempProjectRoot.path,
        pokemonConfig: _pokemonConfig(),
        movesCatalog: movesCatalog,
        playerPokemon: const PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          knownMoveIds: <String>['razor_leaf'],
          currentHp: 23,
        ),
      );

      expect(seed.moves, hasLength(1));
      expect(seed.moves.single.id, equals('razor_leaf'));
      expect(seed.moves.single.critRatio, equals(2));
    });
  });
}

ProjectPokemonConfig _pokemonConfig() {
  return const ProjectPokemonConfig(
    dataRoot: 'custom/pokemon',
    speciesDir: 'custom/pokemon/species',
    learnsetsDir: 'custom/pokemon/learnsets',
    evolutionsDir: 'custom/pokemon/evolutions',
    mediaDir: 'custom/pokemon/media',
    catalogFiles: <String, String>{
      'moves': 'custom/pokemon/catalogs/moves.json',
    },
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'refs': <String, String>{'learnset': 'sproutle'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'refs': <String, String>{'learnset': 'sparkitten'},
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'refs': <String, String>{'learnset': 'aquafi'},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle', 'growl'],
      'relearnMoves': <String>['growl', 'vine_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'vine_whip', 'level': 7},
        <String, Object>{'moveId': 'leer', 'level': 13},
        <String, Object>{'moveId': 'razor_leaf', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'ember', 'level': 7},
        <String, Object>{'moveId': 'flame_wheel', 'level': 20},
      ],
    },
  );
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{'moveId': 'tail_whip', 'level': 18},
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime combatant seed builder test catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('leer', 'Leer', 0),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('quick_attack', 'Quick Attack', 40, priority: 1),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures runtime doivent rester canoniques :
  // - `growl` / `tail_whip` / `leer` portent de vrais effets structurés ;
  // - `thunder_wave` sert maintenant de move de statut majeur réellement
  //   supporté par le petit sous-ensemble BE7 ;
  // - `rain_dance` / `sandstorm` / `trick_room` servent à prouver que le
  //   builder ne reperd pas les nouveaux champs BE9 pendant la projection ;
  // - les autres moves restent de simples attaques standard pour garder les
  //   happy paths lisibles.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' || 'leer' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason:
        'Expected to find move "$moveId" in the combatant seed builder fixture catalog.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{'primary': primaryAbilityId},
      // Le test retire volontairement `refs.learnset` pour prouver que le
      // seam M7 conserve bien le fallback historique vers l'id d'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

~~~~

### `packages/map_runtime/test/runtime_battle_move_bridge_test.dart`

~~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_move_bridge.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_exception.dart';

void main() {
  group('RuntimeBattleMoveBridge', () {
    const bridge = RuntimeBattleMoveBridge();

    test('projects a standard damage move without destroying canonical data',
        () {
      const move = PokemonMove(
        id: 'vine_whip',
        name: 'Vine Whip',
        names: <String, String>{'en': 'Vine Whip'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 45,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('vine_whip'));
      expect(battleMove.power, equals(45));
      expect(battleMove.type, equals('grass'));
      expect(battleMove.category, equals(BattleMoveCategory.physical));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(100));
      expect(battleMove.pp, equals(25));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test('projects a deterministic target stat drop move honestly', () {
      const move = PokemonMove(
        id: 'growl',
        name: 'Growl',
        names: <String, String>{'en': 'Growl'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 40,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.target,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: -1,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.type, equals('normal'));
      expect(battleMove.category, equals(BattleMoveCategory.status));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
      expect(battleMove.pp, equals(40));
      expect(battleMove.selfStatStageChanges, isEmpty);
      expect(battleMove.targetStatStageChanges, hasLength(1));
      expect(
        battleMove.targetStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.targetStatStageChanges.single.stages,
        equals(-1),
      );
    });

    test('projects a deterministic self stat boost move honestly', () {
      const move = PokemonMove(
        id: 'swords_dance',
        name: 'Swords Dance',
        names: <String, String>{'en': 'Swords Dance'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.attack,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.attack),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.pp, equals(20));
      expect(battleMove.targetStatStageChanges, isEmpty);
    });

    test(
        'rejects a self-target damage move that map_battle would still resolve against the opponent',
        () {
      const move = PokemonMove(
        id: 'mind_blown_self',
        name: 'Mind Blown Self',
        names: <String, String>{'en': 'Mind Blown Self'},
        generation: 9,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.self,
        basePower: 50,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=mind_blown_self'),
              contains('bridgeLimit=unsupported_standard_damage_target:self'),
            ),
          ),
        ),
      );
    });

    test(
        'projects a move with non-zero priority once battle order consumes it honestly',
        () {
      const move = PokemonMove(
        id: 'quick_attack',
        name: 'Quick Attack',
        names: <String, String>{'en': 'Quick Attack'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 40,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 30,
        priority: 1,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('quick_attack'));
      expect(battleMove.priority, equals(1));
      expect(battleMove.power, equals(40));
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('projects a deterministic speed boost move honestly', () {
      const move = PokemonMove(
        id: 'agility',
        name: 'Agility',
        names: <String, String>{'en': 'Agility'},
        generation: 1,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 30,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.modifyStats(
            targetScope: PokemonMoveEffectTargetScope.self,
            stageChanges: <PokemonMoveStatStageChange>[
              PokemonMoveStatStageChange(
                stat: PokemonMoveStatId.speed,
                stages: 2,
              ),
            ],
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(battleMove.selfStatStageChanges, hasLength(1));
      expect(
        battleMove.selfStatStageChanges.single.stat,
        equals(BattleStatId.speed),
      );
      expect(
        battleMove.selfStatStageChanges.single.stages,
        equals(2),
      );
    });

    test(
        'projects a move with non-trivial percent accuracy once battle owns the hit check',
        () {
      const move = PokemonMove(
        id: 'fire_blast',
        name: 'Fire Blast',
        names: <String, String>{'en': 'Fire Blast'},
        generation: 1,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 110,
        accuracy: PokemonMoveAccuracy.percent(value: 85),
        pp: 5,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('fire_blast'));
      expect(
        battleMove.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(battleMove.accuracy.value, equals(85));
      expect(battleMove.pp, equals(5));
    });

    test(
        'rejects a move whose type is not actually supported by the current battle type chart',
        () {
      const move = PokemonMove(
        id: 'typo_bolt',
        name: 'Typo Bolt',
        names: <String, String>{'en': 'Typo Bolt'},
        generation: 1,
        source: 'test',
        type: 'electrik',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 80,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=typo_bolt'),
              contains('moveName=Typo Bolt'),
              contains('bridgeLimit=unsupported_type:electrik'),
            ),
          ),
        ),
      );
    });

    test(
        'accepts a move whose non-neutral crit ratio is now transported honestly to battle',
        () {
      const move = PokemonMove(
        id: 'razor_leaf',
        name: 'Razor Leaf',
        names: <String, String>{'en': 'Razor Leaf'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.allAdjacentFoes,
        basePower: 55,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 25,
        critRatio: 2,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.id, equals('razor_leaf'));
      expect(battleMove.critRatio, equals(2));
    });

    test(
        'rejects a target shape that is still outside the honest 1v1 bridge subset',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('moveId=stealth_rock'),
              contains('bridgeLimit=unsupported_target:foeSide'),
            ),
          ),
        ),
      );
    });

    test('supports a deterministic major status move in the BE7 subset', () {
      const move = PokemonMove(
        id: 'thunder_wave',
        name: 'Thunder Wave',
        names: <String, String>{'en': 'Thunder Wave'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(0));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, isNull);
    });

    test(
        'supports a probabilistic major status effect once battle owns the RNG',
        () {
      const move = PokemonMove(
        id: 'thunderbolt',
        name: 'Thunderbolt',
        names: <String, String>{'en': 'Thunderbolt'},
        generation: 1,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 90,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            chance: 10,
            statusId: 'par',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.power, equals(90));
      expect(
        battleMove.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );
      expect(battleMove.majorStatusEffect?.chancePercent, equals(10));
    });

    test(
        'supports the exact protect volatile subset instead of reopening all applyVolatileStatus',
        () {
      const move = PokemonMove(
        id: 'protect',
        name: 'Protect',
        names: <String, String>{'en': 'Protect'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.self,
            volatileStatusId: 'protect',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.self));
      expect(
        battleMove.selfVolatileStatus,
        equals(BattleVolatileStatusId.protect),
      );
    });

    test('supports a breakProtect damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'feint',
        name: 'Feint',
        names: <String, String>{'en': 'Feint'},
        generation: 4,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        target: PokemonMoveTarget.normal,
        basePower: 30,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.breakProtect(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.breaksProtect, isTrue);
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test('supports a requireRecharge damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'hyper_beam',
        name: 'Hyper Beam',
        names: <String, String>{'en': 'Hyper Beam'},
        generation: 1,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 150,
        accuracy: PokemonMoveAccuracy.percent(value: 90),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.requiresRecharge, isTrue);
      expect(battleMove.power, equals(150));
    });

    test('supports a chargeThenStrike damage move in the BE8 subset', () {
      const move = PokemonMove(
        id: 'solar_beam',
        name: 'Solar Beam',
        names: <String, String>{'en': 'Solar Beam'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.chargeThenStrike(chargeStateId: 'solar_charge'),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(
        battleMove.chargeThenStrikeEffect?.chargeStateId,
        equals('solar_charge'),
      );
      expect(battleMove.target, equals(BattleMoveTarget.opponent));
    });

    test(
        'still rejects a noncanonical move that combines chargeThenStrike and requireRecharge',
        () {
      const move = PokemonMove(
        id: 'bad_combo_beam',
        name: 'Bad Combo Beam',
        names: <String, String>{'en': 'Bad Combo Beam'},
        generation: 9,
        source: 'test',
        type: 'normal',
        category: PokemonMoveCategory.special,
        target: PokemonMoveTarget.normal,
        basePower: 120,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.requireRecharge(),
          PokemonMoveEffect.chargeThenStrike(),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_combined_charge_then_recharge',
            ),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported major statuses even when applyStatus is now partially bridgeable',
        () {
      const move = PokemonMove(
        id: 'sleep_powder',
        name: 'Sleep Powder',
        names: <String, String>{'en': 'Sleep Powder'},
        generation: 1,
        source: 'test',
        type: 'grass',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 75),
        pp: 15,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            statusId: 'slp',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_major_status:slp'),
          ),
        ),
      );
    });

    test(
        'still rejects unsupported applyVolatileStatus outside the protect subset',
        () {
      const move = PokemonMove(
        id: 'confuse_ray',
        name: 'Confuse Ray',
        names: <String, String>{'en': 'Confuse Ray'},
        generation: 1,
        source: 'test',
        type: 'ghost',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.normal,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.applyVolatileStatus(
            targetScope: PokemonMoveEffectTargetScope.target,
            volatileStatusId: 'confusion',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains(
              'bridgeLimit=unsupported_apply_volatile_status_scope:target',
            ),
          ),
        ),
      );
    });

    test('supports the exact Rain Dance weather subset in BE9', () {
      const move = PokemonMove(
        id: 'rain_dance',
        name: 'Rain Dance',
        names: <String, String>{'en': 'Rain Dance'},
        generation: 2,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.rain));
      expect(battleMove.pseudoWeatherEffect, isNull);
    });

    test(
        'rejects a malformed self-target field move instead of widening the BE9 field contract',
        () {
      const move = PokemonMove(
        id: 'bad_self_rain',
        name: 'Bad Self Rain',
        names: <String, String>{'en': 'Bad Self Rain'},
        generation: 9,
        source: 'test',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'raindance',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_field_target:self'),
          ),
        ),
      );
    });

    test('supports the exact Sandstorm weather subset in BE9', () {
      const move = PokemonMove(
        id: 'sandstorm',
        name: 'Sandstorm',
        names: <String, String>{'en': 'Sandstorm'},
        generation: 2,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sandstorm',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(battleMove.weatherEffect, equals(BattleWeatherId.sandstorm));
    });

    test(
        'supports the exact Trick Room pseudoWeather subset without reopening all structuredPartial moves',
        () {
      const move = PokemonMove(
        id: 'trick_room',
        name: 'Trick Room',
        names: <String, String>{'en': 'Trick Room'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        priority: -7,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'trickroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: <String>[
          'unsupported_mechanic:turn_order_inversion',
          'showdown_callback:condition.durationCallback',
          'showdown_callback:condition.onFieldEnd',
        ],
      );

      final battleMove = bridge.toBattleMoveData(
        move: move,
        combatantLabel: 'Le Pokémon actif du joueur',
      );

      expect(battleMove.target, equals(BattleMoveTarget.field));
      expect(
        battleMove.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(battleMove.priority, equals(-7));
    });

    test('still rejects unsupported weather ids outside the BE9 subset', () {
      const move = PokemonMove(
        id: 'sunny_day',
        name: 'Sunny Day',
        names: <String, String>{'en': 'Sunny Day'},
        generation: 2,
        source: 'test',
        type: 'fire',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 5,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            weatherId: 'sunnyday',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_weather:sunnyday'),
          ),
        ),
      );
    });

    test('still rejects unsupported pseudoWeather ids outside the BE9 subset',
        () {
      const move = PokemonMove(
        id: 'magic_room',
        name: 'Magic Room',
        names: <String, String>{'en': 'Magic Room'},
        generation: 5,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setPseudoWeather(
            targetScope: PokemonMoveEffectTargetScope.field,
            pseudoWeatherId: 'magicroom',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            contains('bridgeLimit=unsupported_pseudo_weather:magicroom'),
          ),
        ),
      );
    });

    test('still rejects setTerrain because BE9 does not open terrains', () {
      const move = PokemonMove(
        id: 'electric_terrain',
        name: 'Electric Terrain',
        names: <String, String>{'en': 'Electric Terrain'},
        generation: 6,
        source: 'test',
        type: 'electric',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.all,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setTerrain(
            targetScope: PokemonMoveEffectTargetScope.field,
            terrainId: 'electricterrain',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:all'),
              contains('bridgeLimit=unsupported_effect_kind:set_terrain'),
            ),
          ),
        ),
      );
    });

    test('still rejects setSideCondition because BE9 does not open side state',
        () {
      const move = PokemonMove(
        id: 'stealth_rock',
        name: 'Stealth Rock',
        names: <String, String>{'en': 'Stealth Rock'},
        generation: 4,
        source: 'test',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 20,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(
            targetScope: PokemonMoveEffectTargetScope.foeSide,
            conditionId: 'stealthrock',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:foeSide'),
              contains(
                  'bridgeLimit=unsupported_effect_kind:set_side_condition'),
            ),
          ),
        ),
      );
    });

    test('still rejects setSlotCondition because BE9 does not open slot state',
        () {
      const move = PokemonMove(
        id: 'healing_wish',
        name: 'Healing Wish',
        names: <String, String>{'en': 'Healing Wish'},
        generation: 4,
        source: 'test',
        type: 'psychic',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        basePower: 0,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        pp: 10,
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSlotCondition(
            targetScope: PokemonMoveEffectTargetScope.slot,
            conditionId: 'healingwish',
          ),
        ],
        engineSupportLevel: PokemonMoveEngineSupportLevel.structuredSupported,
      );

      expect(
        () => bridge.toBattleMoveData(
          move: move,
          combatantLabel: 'Le Pokémon actif du joueur',
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            anyOf(
              contains('bridgeLimit=unsupported_target:self'),
              contains(
                  'bridgeLimit=unsupported_effect_kind:set_slot_condition'),
              contains('bridgeLimit=unsupported_target:slot'),
            ),
          ),
        ),
      );
    });
  });
}

~~~~

### `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_battle_setup_mapper.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuntimeBattleSetupMapper', () {
    late Directory tempProjectRoot;
    const mapper = RuntimeBattleSetupMapper();

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('runtime_battle_mapper_');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    test('maps the real player party member from runtime save data', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player',
          party: PlayerParty(
            members: <PlayerPokemon>[
              // Ce Pokémon K.O. ne doit jamais être choisi par le mapper.
              PlayerPokemon(
                speciesId: 'spentmon',
                natureId: 'hardy',
                abilityId: 'pressure',
                level: 99,
                knownMoveIds: <String>['do-not-use'],
                currentHp: 0,
              ),
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                ivs: PokemonStatSpread(hp: 31),
                evs: PokemonStatSpread(hp: 8),
                knownMoveIds: <String>['growl', 'vine_whip'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.speciesId, equals('sproutle'));
      expect(setup.playerPokemon.level, equals(12));
      expect(setup.playerPokemon.currentHp, equals(23));
      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.playerPokemon.typing!.primaryType, equals('grass'));
      expect(setup.playerPokemon.typing!.secondaryType, isNull);
      expect(setup.playerPokemon.stats.attack, equals(16));
      expect(setup.playerPokemon.stats.specialAttack, equals(20));
      expect(setup.playerPokemon.stats.speed, equals(15));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['growl', 'vine_whip']),
      );
      expect(setup.playerPokemon.speciesId, isNot(equals('pikachu')));
    });

    test('uses the explicit player party index when the runtime provides one',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-player-index',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'hardy',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['growl'],
                currentHp: 21,
              ),
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun', 'tail_whip'],
                currentHp: 17,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
        playerPartyIndex: 1,
      );

      expect(setup.playerPokemon.speciesId, equals('aquafi'));
      expect(setup.playerPokemon.currentHp, equals(17));
      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
    });

    test('maps a wild encounter from real project species and learnset data',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isTrue);
      expect(setup.enemyPokemon.speciesId, equals('sparkitten'));
      expect(setup.enemyPokemon.level, equals(10));
      expect(setup.enemyPokemon.abilityId, equals('blaze'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('fire'));
      expect(setup.enemyPokemon.typing!.secondaryType, isNull);
      expect(setup.enemyPokemon.stats.attack, equals(15));
      expect(setup.enemyPokemon.stats.specialAttack, equals(17));
      expect(setup.enemyPokemon.stats.speed, equals(18));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['scratch', 'tail_whip', 'ember']),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'scratch')
            .power,
        equals(40),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .power,
        equals(0),
      );
      expect(
        setup.enemyPokemon.moves
            .firstWhere((move) => move.id == 'tail_whip')
            .targetStatStageChanges
            .single
            .stat,
        equals(BattleStatId.defense),
      );
      expect(
        setup.enemyPokemon.moves.map((move) => move.id),
        isNot(contains('flame_wheel')),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('mew')));
    });

    test(
        'preserves typing through to battle so STAB and effectiveness are really consumed',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-type-bridge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 12,
                knownMoveIds: <String>['ember'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sproutle',
          level: 10,
        ),
      );

      final session = createBattleSession(setup).applyChoice(
        const PlayerBattleChoiceFight(0),
      );
      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );

      expect(setup.playerPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(execution.move.id, equals('ember'));
      expect(execution.didHit, isTrue);
      expect(execution.stabMultiplier, equals(1.5));
      expect(execution.typeEffectivenessMultiplier, equals(2.0));
      expect(execution.damage, greaterThan(0));
    });

    test(
        'maps a non-trivial accuracy move honestly through to battle, where it can miss deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-accuracy',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['mud_slap'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(
        setup.playerPokemon.moves.single.accuracy.kind,
        equals(BattleMoveAccuracyKind.percent),
      );
      expect(setup.playerPokemon.moves.single.accuracy.value, equals(85));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 100]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('mud_slap'));
      expect(execution.didHit, isFalse);
      expect(session.state.enemy.currentHp, equals(setup.enemyPokemon.maxHp));
    });

    test(
        'maps a non-neutral crit ratio honestly through to battle, where it can crit deterministically',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-crits',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['razor_leaf'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves, hasLength(1));
      expect(setup.playerPokemon.moves.single.id, equals('razor_leaf'));
      expect(setup.playerPokemon.moves.single.critRatio, equals(2));

      final session = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[2, 1]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      final execution = session.state.currentTurn!.executions.firstWhere(
        (execution) => execution.attacker == 'player',
      );
      expect(execution.move.id, equals('razor_leaf'));
      expect(execution.didHit, isTrue);
      expect(execution.didCrit, isTrue);
      expect(execution.criticalMultiplier, equals(1.5));
      expect(execution.damage, greaterThan(0));
    });

    test('falls back to the species id when the species has no learnset ref',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteSpeciesWithoutLearnsetRef(
        tempProjectRoot,
        speciesFileName: '001-sproutle.json',
        speciesId: 'sproutle',
        baseHp: 45,
        primaryAbilityId: 'overgrow',
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-species-id-fallback',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['tackle', 'growl', 'vine_whip']),
      );
    });

    test('disables capture in wild battles when the bag has no poke-ball',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(
          bag: const Bag(),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test('maps a trainer battle from the authored trainer team', () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[
          ProjectTrainerEntry(
            id: 'trainer_ace',
            name: 'Ace Jules',
            trainerClass: 'Ace Trainer',
            team: <ProjectTrainerPokemonEntry>[
              ProjectTrainerPokemonEntry(
                speciesId: 'aquafi',
                level: 18,
                moves: <String>['water_gun', 'tail_whip'],
                heldItemId: 'mystic_water',
              ),
            ],
          ),
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final setup = await mapper.map(
        bundle: bundle,
        gameState: _playerStateForTests(),
        request: _trainerRequest(),
      );

      expect(setup.isTrainerBattle, isTrue);
      expect(setup.allowCapture, isFalse);
      expect(setup.trainerId, equals('trainer_ace'));
      expect(setup.enemyPokemon.speciesId, equals('aquafi'));
      expect(setup.enemyPokemon.level, equals(18));
      expect(setup.enemyPokemon.abilityId, equals('torrent'));
      expect(setup.enemyPokemon.typing, isNotNull);
      expect(setup.enemyPokemon.typing!.primaryType, equals('water'));
      expect(setup.enemyPokemon.typing!.secondaryType, equals('fairy'));
      expect(
        setup.enemyPokemon.moves.map((move) => move.id).toList(),
        equals(<String>['water_gun', 'tail_whip']),
      );
      expect(setup.enemyPokemon.speciesId, isNot(equals('lapras')));
    });

    test('disables capture in wild battles when the party is already full',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);
      final fullPartyState = GameState(
        saveId: 'save-full-party',
        bag: const Bag(
          entries: <BagEntry>[
            BagEntry(
              itemId: 'poke-ball',
              categoryId: 'items',
              quantity: 2,
            ),
          ],
        ),
        party: PlayerParty(
          members: List<PlayerPokemon>.generate(
            6,
            (index) => PlayerPokemon(
              speciesId: 'sproutle',
              natureId: 'bold',
              abilityId: 'overgrow',
              level: 12 + index,
              knownMoveIds: const <String>['growl'],
              currentHp: 20,
            ),
            growable: false,
          ),
        ),
      );

      final setup = await mapper.map(
        bundle: bundle,
        gameState: fullPartyState,
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.isTrainerBattle, isFalse);
      expect(setup.allowCapture, isFalse);
    });

    test(
        'throws explicitly when a runtime move reference is absent from the canonical catalog',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-missing-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['move_that_does_not_exist'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.message,
            'message',
            contains('ne contient pas "move_that_does_not_exist"'),
          ),
        ),
      );
    });

    test(
        'rejects an explicitly known move when its runtime support level is only partial',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'growl',
        supportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:stat_drop_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-unsupported-known-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  knownMoveIds: <String>['growl', 'vine_whip'],
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>()
              .having(
                (error) => error.message,
                'message',
                contains('ne sait pas projeter honnêtement'),
              )
              .having(
                (error) => error.debugDetails,
                'debugDetails',
                allOf(
                  contains('combatant=Le Pokémon actif du joueur'),
                  contains('moveId=growl'),
                  contains('moveName=Growl'),
                  contains('engineSupportLevel=structuredPartial'),
                  contains(
                    'unsupportedReasons=[unsupported_mechanic:stat_drop_bridge]',
                  ),
                ),
              ),
        ),
      );
    });

    test(
        'rejects a learnset-derived move when its runtime support level is catalog only',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      await _rewriteMoveCatalogEntrySupport(
        tempProjectRoot,
        moveId: 'tackle',
        supportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        unsupportedReasons: const <String>[
          'unsupported_mechanic:legacy_damage_bridge',
        ],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      await expectLater(
        () => mapper.map(
          bundle: bundle,
          gameState: const GameState(
            saveId: 'save-derived-unsupported-move',
            party: PlayerParty(
              members: <PlayerPokemon>[
                PlayerPokemon(
                  speciesId: 'sproutle',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 12,
                  currentHp: 20,
                ),
              ],
            ),
          ),
          request: _wildRequest(
            speciesId: 'sparkitten',
            level: 10,
          ),
        ),
        throwsA(
          isA<RuntimeBattleSetupException>().having(
            (error) => error.debugDetails,
            'debugDetails',
            allOf(
              contains('combatant=Le Pokémon actif du joueur'),
              contains('moveId=tackle'),
              contains('moveName=Tackle'),
              contains('engineSupportLevel=catalogOnly'),
              contains(
                'unsupportedReasons=[unsupported_mechanic:legacy_damage_bridge]',
              ),
            ),
          ),
        ),
      );
    });

    test(
        'maps a supported major status move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-major-status',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['thunder_wave'],
                currentHp: 20,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(setup.playerPokemon.moves.single.id, equals('thunder_wave'));
      expect(
        setup.playerPokemon.moves.single.majorStatusEffect?.status,
        equals(BattleMajorStatusId.par),
      );

      final session = createBattleSession(setup);
      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterTurn.state.enemy.majorStatus?.id,
          equals(BattleMajorStatusId.par));
      expect(
        afterTurn.state.currentTurn?.statusEvents
            .where((event) => event.kind == BattleStatusEventKind.applied)
            .single
            .sourceMoveId,
        equals('thunder_wave'),
      );
    });

    test(
        'maps a supported requireRecharge move and keeps the forced follow-up honest in battle',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-supported-recharge',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sparkitten',
                natureId: 'bold',
                abilityId: 'blaze',
                level: 80,
                knownMoveIds: <String>['hyper_beam'],
                currentHp: 120,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'aquafi',
          level: 80,
        ),
      );

      expect(setup.playerPokemon.moves.single.requiresRecharge, isTrue);

      final afterAttack = createBattleSession(
        setup,
        rng: const BattleScriptedRng(<int>[1, 24, 24, 24]),
      ).applyChoice(const PlayerBattleChoiceFight(0));

      expect(afterAttack.state.player.volatileState.mustRecharge, isTrue);
      expect(afterAttack.getAvailableChoices().single,
          isA<PlayerBattleChoiceContinue>());

      final afterRecharge =
          afterAttack.applyChoice(const PlayerBattleChoiceContinue());

      expect(afterRecharge.state.player.volatileState.mustRecharge, isFalse);
      expect(
        afterRecharge.state.currentTurn?.volatileEvents
            .where((event) =>
                event.kind == BattleVolatileEventKind.rechargeTurnSpent)
            .single
            .actor,
        equals('player'),
      );
    });

    test('maps a supported weather move and lets battle consume rain honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final rainySetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-dance',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['rain_dance', 'water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        rainySetup.playerPokemon.moves.first.weatherEffect,
        equals(BattleWeatherId.rain),
      );

      final rainySession = createBattleSession(rainySetup);
      final afterRain =
          rainySession.applyChoice(const PlayerBattleChoiceFight(0));
      final rainyAttack =
          afterRain.applyChoice(const PlayerBattleChoiceFight(1));
      final rainyDamage = rainyAttack.state.currentTurn!.executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      final neutralSetup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-rain-neutral',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'aquafi',
                natureId: 'calm',
                abilityId: 'torrent',
                level: 18,
                knownMoveIds: <String>['water_gun'],
                currentHp: 42,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      final neutralDamage = createBattleSession(neutralSetup)
          .applyChoice(const PlayerBattleChoiceFight(0))
          .state
          .currentTurn!
          .executions
          .firstWhere((execution) => execution.attacker == 'player')
          .damage;

      expect(afterRain.state.field.weather?.id, equals(BattleWeatherId.rain));
      expect(
        afterRain.state.currentTurn!.fieldEvents
            .where((event) => event.kind == BattleFieldEventKind.weatherSet)
            .single
            .weather,
        equals(BattleWeatherId.rain),
      );
      expect(rainyDamage, greaterThan(neutralDamage));
    });

    test('maps a supported Trick Room move and lets battle consume it honestly',
        () async {
      final manifest = await _writeAndLoadProjectManifest(
        tempProjectRoot,
        trainers: const <ProjectTrainerEntry>[],
      );
      final bundle = _buildRuntimeBundle(tempProjectRoot.path, manifest);

      final setup = await mapper.map(
        bundle: bundle,
        gameState: const GameState(
          saveId: 'save-trick-room',
          party: PlayerParty(
            members: <PlayerPokemon>[
              PlayerPokemon(
                speciesId: 'sproutle',
                natureId: 'bold',
                abilityId: 'overgrow',
                level: 12,
                knownMoveIds: <String>['trick_room', 'tackle'],
                currentHp: 23,
              ),
            ],
          ),
        ),
        request: _wildRequest(
          speciesId: 'sparkitten',
          level: 10,
        ),
      );

      expect(
        setup.playerPokemon.moves.first.pseudoWeatherEffect,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(setup.playerPokemon.moves.first.priority, equals(-7));

      final session = createBattleSession(setup);
      final afterRoom = session.applyChoice(const PlayerBattleChoiceFight(0));
      final afterAttack =
          afterRoom.applyChoice(const PlayerBattleChoiceFight(1));

      expect(
        afterRoom.state.field.pseudoWeather?.id,
        equals(BattlePseudoWeatherId.trickRoom),
      );
      expect(
        afterAttack.state.currentTurn!.executions.first.attacker,
        equals('player'),
      );
    });
  });
}

GameState _playerStateForTests({
  Bag bag = const Bag(
    entries: <BagEntry>[
      BagEntry(
        itemId: 'poke-ball',
        categoryId: 'items',
        quantity: 2,
      ),
    ],
  ),
}) {
  return GameState(
    saveId: 'save-test',
    bag: bag,
    party: const PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'bold',
          abilityId: 'overgrow',
          level: 12,
          ivs: PokemonStatSpread(hp: 31),
          evs: PokemonStatSpread(hp: 8),
          knownMoveIds: <String>['growl', 'vine_whip'],
          currentHp: 23,
        ),
      ],
    ),
  );
}

RuntimeMapBundle _buildRuntimeBundle(
  String projectRootDirectory,
  ProjectManifest manifest,
) {
  return RuntimeMapBundle(
    manifest: manifest,
    map: const MapData(
      id: 'field_map',
      name: 'Field Map',
      size: GridSize(width: 8, height: 8),
      layers: <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
    ),
    projectRootDirectory: projectRootDirectory,
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

WildBattleStartRequest _wildRequest({
  required String speciesId,
  required int level,
}) {
  return WildBattleStartRequest(
    requestId: 'wild-request',
    createdAtEpochMs: 1,
    returnContext: const OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    mapId: 'field_map',
    zoneId: 'grass',
    tableId: 'field_grass',
    encounterKind: EncounterKind.walk,
    speciesId: speciesId,
    level: level,
    minLevel: level,
    maxLevel: level,
    weight: 30,
    playerPos: const GridPos(x: 1, y: 1),
  );
}

TrainerBattleStartRequest _trainerRequest() {
  return const TrainerBattleStartRequest(
    requestId: 'trainer-request',
    createdAtEpochMs: 1,
    returnContext: OverworldReturnContext(
      mapId: 'field_map',
      playerPos: GridPos(x: 1, y: 1),
      playerFacing: Direction.south,
    ),
    trainerId: 'trainer_ace',
    npcEntityId: 'npc_ace',
    mapId: 'field_map',
    playerPos: GridPos(x: 1, y: 1),
  );
}

Future<ProjectManifest> _writeAndLoadProjectManifest(
  Directory projectRoot, {
  required List<ProjectTrainerEntry> trainers,
}) async {
  final manifest = ProjectManifest(
    name: 'Battle Mapper Test',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'field_map',
        name: 'Field Map',
        relativePath: 'maps/field_map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    trainers: trainers,
    pokemon: const ProjectPokemonConfig(
      dataRoot: 'custom/pokemon',
      speciesDir: 'custom/pokemon/species',
      learnsetsDir: 'custom/pokemon/learnsets',
      evolutionsDir: 'custom/pokemon/evolutions',
      mediaDir: 'custom/pokemon/media',
      catalogFiles: <String, String>{
        'moves': 'custom/pokemon/catalogs/moves.json',
      },
    ),
  );

  await _writeProjectJson(projectRoot, manifest.toJson());
  await _writePokemonFixtures(projectRoot);

  return loadProjectManifestFromFile(p.join(projectRoot.path, 'project.json'));
}

Future<void> _writeProjectJson(
  Directory projectRoot,
  Map<String, dynamic> json,
) async {
  final file = File(p.join(projectRoot.path, 'project.json'));
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

Future<void> _writePokemonFixtures(Directory projectRoot) async {
  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/001-sproutle.json',
    <String, dynamic>{
      'id': 'sproutle',
      'slug': 'sproutle',
      'nationalDex': 1,
      'names': <String, String>{'en': 'Sproutle'},
      'speciesName': <String, String>{'en': 'Seedling'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': 45,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
        'bst': 318,
      },
      'abilities': <String, String>{'primary': 'overgrow'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['monster', 'grass'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 64,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sproutle',
        'evolution': 'sproutle',
        'media': 'sproutle',
      },
      'dexContent': <String, Object>{
        'heightM': 0.7,
        'weightKg': 6.9,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/004-sparkitten.json',
    <String, dynamic>{
      'id': 'sparkitten',
      'slug': 'sparkitten',
      'nationalDex': 4,
      'names': <String, String>{'en': 'Sparkitten'},
      'speciesName': <String, String>{'en': 'Ember Cat'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['fire'],
      },
      'baseStats': <String, int>{
        'hp': 39,
        'atk': 52,
        'def': 43,
        'spa': 60,
        'spd': 50,
        'spe': 65,
        'bst': 309,
      },
      'abilities': <String, String>{'primary': 'blaze'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.875, 'female': 0.125},
        'eggGroups': <String>['field'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 62,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'sparkitten',
        'evolution': 'sparkitten',
        'media': 'sparkitten',
      },
      'dexContent': <String, Object>{
        'heightM': 0.6,
        'weightKg': 8.5,
      },
      'gameplayFlags': <String, bool>{'starterEligible': true},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/007-aquafi.json',
    <String, dynamic>{
      'id': 'aquafi',
      'slug': 'aquafi',
      'nationalDex': 7,
      'names': <String, String>{'en': 'Aquafi'},
      'speciesName': <String, String>{'en': 'Tadpole'},
      'genIntroduced': 1,
      'typing': <String, Object>{
        'types': <String>['water', 'fairy'],
      },
      'baseStats': <String, int>{
        'hp': 44,
        'atk': 48,
        'def': 65,
        'spa': 50,
        'spd': 64,
        'spe': 43,
        'bst': 314,
      },
      'abilities': <String, String>{'primary': 'torrent'},
      'breeding': <String, Object>{
        'genderRatio': <String, double>{'male': 0.5, 'female': 0.5},
        'eggGroups': <String>['water_1'],
        'hatchCycles': 20,
      },
      'progression': <String, Object>{
        'growthRateId': 'medium_slow',
        'baseExp': 63,
        'catchRate': 45,
        'baseFriendship': 50,
      },
      'refs': <String, String>{
        'learnset': 'aquafi',
        'evolution': 'aquafi',
        'media': 'aquafi',
      },
      'dexContent': <String, Object>{
        'heightM': 0.5,
        'weightKg': 9.0,
      },
      'gameplayFlags': <String, bool>{'starterEligible': false},
      'sourceMeta': <String, Object>{'seededBy': 'test', 'seedVersion': 1},
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sproutle.json',
    <String, dynamic>{
      'speciesId': 'sproutle',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['growl'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'vine_whip',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'razor_leaf',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/sparkitten.json',
    <String, dynamic>{
      'speciesId': 'sparkitten',
      'startingMoves': <String>['scratch'],
      'relearnMoves': <String>['tail_whip'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'ember',
          'level': 7,
          'source': 'level_up',
          'versionGroup': 'project',
        },
        <String, Object>{
          'moveId': 'flame_wheel',
          'level': 20,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/learnsets/aquafi.json',
    <String, dynamic>{
      'speciesId': 'aquafi',
      'startingMoves': <String>['tackle'],
      'relearnMoves': <String>['water_gun'],
      'levelUp': <Map<String, Object>>[
        <String, Object>{
          'moveId': 'tail_whip',
          'level': 18,
          'source': 'level_up',
          'versionGroup': 'project',
        },
      ],
    },
  );

  await _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/catalogs/moves.json',
    <String, dynamic>{
      'schemaVersion': 1,
      'kind': 'pokemon_catalog',
      'catalog': 'moves',
      'meta': <String, Object>{
        'description': 'Runtime test move catalog',
      },
      'entries': <Map<String, Object?>>[
        _moveEntry('tackle', 'Tackle', 40),
        _moveEntry('growl', 'Growl', 0),
        _moveEntry('vine_whip', 'Vine Whip', 45, type: 'grass'),
        _moveEntry('razor_leaf', 'Razor Leaf', 55, type: 'grass', critRatio: 2),
        _moveEntry('scratch', 'Scratch', 40),
        _moveEntry('mud_slap', 'Mud-Slap', 20, type: 'ground', accuracy: 85),
        _moveEntry('tail_whip', 'Tail Whip', 0),
        _moveEntry('ember', 'Ember', 40, type: 'fire'),
        _moveEntry('flame_wheel', 'Flame Wheel', 60, type: 'fire'),
        _moveEntry('water_gun', 'Water Gun', 40, type: 'water'),
        _moveEntry('thunder_wave', 'Thunder Wave', 0, type: 'electric'),
        _moveEntry(
          'protect',
          'Protect',
          0,
          target: PokemonMoveTarget.self,
          pp: 10,
        ),
        _moveEntry('feint', 'Feint', 30, pp: 10),
        _moveEntry('hyper_beam', 'Hyper Beam', 150, pp: 5, accuracy: 90),
        _moveEntry('solar_beam', 'Solar Beam', 120, type: 'grass', pp: 10),
        _moveEntry(
          'rain_dance',
          'Rain Dance',
          0,
          type: 'water',
          target: PokemonMoveTarget.all,
          pp: 5,
        ),
        _moveEntry(
          'sandstorm',
          'Sandstorm',
          0,
          type: 'rock',
          target: PokemonMoveTarget.all,
          pp: 10,
        ),
        _moveEntry(
          'trick_room',
          'Trick Room',
          0,
          type: 'psychic',
          target: PokemonMoveTarget.all,
          pp: 5,
          priority: -7,
          engineSupportLevel: PokemonMoveEngineSupportLevel.structuredPartial,
          unsupportedReasons: const <String>[
            'unsupported_mechanic:turn_order_inversion',
            'showdown_callback:condition.durationCallback',
            'showdown_callback:condition.onFieldEnd',
          ],
        ),
      ],
    },
  );
}

Map<String, Object?> _moveEntry(
  String id,
  String name,
  int power, {
  String type = 'normal',
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  int pp = 35,
  int accuracy = 100,
  int priority = 0,
  int critRatio = 1,
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  List<String> unsupportedReasons = const <String>[],
}) {
  final effects = _defaultEffectsForMove(id);
  return PokemonMove(
    id: id,
    name: name,
    names: <String, String>{'en': name},
    generation: 1,
    source: 'test_runtime_fixture',
    type: type,
    category:
        power == 0 ? PokemonMoveCategory.status : PokemonMoveCategory.special,
    target: target,
    basePower: power,
    accuracy: power == 0
        ? const PokemonMoveAccuracy.alwaysHits()
        : PokemonMoveAccuracy.percent(value: accuracy),
    pp: pp,
    priority: priority,
    critRatio: critRatio,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    unsupportedReasons: unsupportedReasons,
  ).toJson();
}

List<PokemonMoveEffect> _defaultEffectsForMove(String moveId) {
  // Ces fixtures de mapper restent volontairement petites et canoniques :
  // - on encode seulement les effets déjà réellement consommés par le moteur ;
  // - BE9 ajoute ici juste assez de champ pour pluie / tempête de sable /
  //   Trick Room ;
  // - on ne crée pas un faux mini-catalogue parallèle plus riche que le repo.
  return switch (moveId) {
    'growl' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.attack,
              stages: -1,
            ),
          ],
        ),
      ],
    'tail_whip' => const <PokemonMoveEffect>[
        PokemonMoveEffect.modifyStats(
          targetScope: PokemonMoveEffectTargetScope.target,
          stageChanges: <PokemonMoveStatStageChange>[
            PokemonMoveStatStageChange(
              stat: PokemonMoveStatId.defense,
              stages: -1,
            ),
          ],
        ),
      ],
    'thunder_wave' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyStatus(
          targetScope: PokemonMoveEffectTargetScope.target,
          statusId: 'par',
        ),
      ],
    'protect' => const <PokemonMoveEffect>[
        PokemonMoveEffect.applyVolatileStatus(
          targetScope: PokemonMoveEffectTargetScope.self,
          volatileStatusId: 'protect',
        ),
      ],
    'feint' => const <PokemonMoveEffect>[
        PokemonMoveEffect.breakProtect(),
      ],
    'hyper_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.requireRecharge(),
      ],
    'solar_beam' => const <PokemonMoveEffect>[
        PokemonMoveEffect.chargeThenStrike(
          chargeStateId: 'solar_charge',
        ),
      ],
    'rain_dance' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'raindance',
        ),
      ],
    'sandstorm' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          weatherId: 'sandstorm',
        ),
      ],
    'trick_room' => const <PokemonMoveEffect>[
        PokemonMoveEffect.setPseudoWeather(
          targetScope: PokemonMoveEffectTargetScope.field,
          pseudoWeatherId: 'trickroom',
        ),
      ],
    _ => const <PokemonMoveEffect>[],
  };
}

Future<void> _rewriteMoveCatalogEntrySupport(
  Directory projectRoot, {
  required String moveId,
  required PokemonMoveEngineSupportLevel supportLevel,
  required List<String> unsupportedReasons,
}) async {
  final catalogFile =
      File(p.join(projectRoot.path, 'custom/pokemon/catalogs/moves.json'));
  final decoded =
      jsonDecode(await catalogFile.readAsString()) as Map<String, dynamic>;
  final rawEntries =
      ((decoded['entries'] as List?) ?? const <Object?>[]).cast<Object?>();
  final updatedEntries = <Map<String, Object?>>[];
  var replaced = false;

  // Le helper reste volontairement minimal :
  // - il ne change que le niveau de support/runtime reasons d'une entrée déjà
  //   canonique ;
  // - il évite de dupliquer un second seed de test complet juste pour deux
  //   cas M5-bis ;
  // - il garde les fixtures globales existantes lisibles et stables.
  for (final rawEntry in rawEntries) {
    final entry = (rawEntry as Map).cast<String, dynamic>();
    final entryId = (entry['id'] as String?)?.trim() ?? '';
    if (entryId != moveId) {
      updatedEntries.add(Map<String, Object?>.from(entry));
      continue;
    }

    replaced = true;
    final move = PokemonMove.fromJson(entry).copyWith(
      engineSupportLevel: supportLevel,
      unsupportedReasons: unsupportedReasons,
    );
    updatedEntries.add(move.toJson());
  }

  expect(
    replaced,
    isTrue,
    reason: 'Expected to find move "$moveId" in the canonical runtime fixture.',
  );

  decoded['entries'] = updatedEntries;
  await catalogFile.writeAsString(const JsonEncoder.withIndent('  ').convert(
    decoded,
  ));
}

Future<void> _rewriteSpeciesWithoutLearnsetRef(
  Directory projectRoot, {
  required String speciesFileName,
  required String speciesId,
  required int baseHp,
  required String primaryAbilityId,
}) {
  return _writeProjectRelativeJson(
    projectRoot,
    'custom/pokemon/species/$speciesFileName',
    <String, dynamic>{
      'id': speciesId,
      'typing': <String, Object>{
        'types': <String>['grass'],
      },
      'baseStats': <String, int>{
        'hp': baseHp,
        'atk': 49,
        'def': 49,
        'spa': 65,
        'spd': 65,
        'spe': 45,
      },
      'abilities': <String, String>{
        'primary': primaryAbilityId,
      },
      // Ce helper retire volontairement `refs.learnset` pour vérifier que le
      // mapper, via le loader learnset, retombe bien sur l'id de l'espèce.
    },
  );
}

Future<void> _writeProjectRelativeJson(
  Directory projectRoot,
  String relativePath,
  Map<String, dynamic> json,
) async {
  final absolutePath = p.join(projectRoot.path, relativePath);
  final file = File(absolutePath);
  await file.parent.create(recursive: true);
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
}

~~~~
